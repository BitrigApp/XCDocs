import Foundation
import XCDocsBridge

package final class VectorSearchClient {
  private enum SearchConfiguration {
    static let numberOfProbes = 8
    static let batchSize = 64
    static let concurrentReaders = 2
  }

  private let client: VSKClientObject

  package init(
    databaseDirectoryURL: URL,
    readOnly: Bool
  ) throws {
    let config = try VSKConfigObject(
      baseDirectoryURL: databaseDirectoryURL,
      numberOfProbes: SearchConfiguration.numberOfProbes,
      readOnly: readOnly
    )
    self.client = try VSKClientObject(config: config)
  }

  package func search(
    vector: Data,
    frameworks: [String],
    kinds: [String],
    limit: Int,
    includeContent: Bool
  ) throws -> [VectorSearchHit] {
    guard limit > 0 else { return [] }

    let filters = try makeFilters(
      attributeName: "framework",
      values: frameworks
    ) + makeFilters(
      attributeName: "type",
      values: kinds
    )
    var selectedAttributes = [
      try VSKAttributeObject.stringNamed("framework"),
      try VSKAttributeObject.stringNamed("type"),
      try VSKAttributeObject.stringNamed("title"),
    ]
    if includeContent {
      selectedAttributes.append(try VSKAttributeObject.stringNamed("content"))
    }

    let rawResults = try client.search(
      vector: vector,
      stringIdentifiers: nil,
      attributeFilters: filters,
      selectAttributes: selectedAttributes,
      limit: limit,
      fullScan: true,
      numberOfProbes: SearchConfiguration.numberOfProbes,
      batchSize: SearchConfiguration.batchSize,
      numConcurrentReaders: SearchConfiguration.concurrentReaders
    )

    let hits = rawResults.map {
      VectorSearchHit(
        identifier: $0.stringIdentifier,
        score: $0.score,
        attributes: $0.attributes
      )
    }

    return try hydrateSearchHits(
      hits,
      selectedAttributes: selectedAttributes
    )
  }

  package func fetch(identifier: String) throws -> VectorSearchHit? {
    let selectedAttributes = [
      try VSKAttributeObject.stringNamed("framework"),
      try VSKAttributeObject.stringNamed("type"),
      try VSKAttributeObject.stringNamed("title"),
      try VSKAttributeObject.stringNamed("content"),
    ]

    guard
      let asset = try client.stringIdentifiedAssets(
        identifiers: [identifier],
        attributeFilters: [],
        includeVectors: false,
        selectAttributes: selectedAttributes
      ).first
    else {
      return nil
    }

    return VectorSearchHit(
      identifier: asset.stringIdentifier,
      score: .nan,
      attributes: asset.attributes
    )
  }

  // MARK: Private

  private func makeFilters(
    attributeName: String,
    values: [String]
  ) throws -> [VSKFilterObject] {
    let normalizedValues =
      values
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    guard !normalizedValues.isEmpty else {
      return []
    }

    let attribute = try VSKAttributeObject.stringNamed(attributeName)
    let disjunctiveFilters = try normalizedValues.map { value in
      try VSKDisjunctiveFilterObject(
        operatorRawValue: VSKFilterOperator.equals.rawValue,
        value: VSKDatabaseValueObject(string: value)
      )
    }

    return [try VSKFilterObject(attribute: attribute, disjunctiveFilters: disjunctiveFilters)]
  }

  private func hydrateSearchHits(
    _ hits: [VectorSearchHit],
    selectedAttributes: [VSKAttributeObject]
  ) throws -> [VectorSearchHit] {
    let attributeNames = selectedAttributes.map(\.name)
    let incompleteIdentifiers = Array(
      Set(
        hits
          .filter { hit in
            attributeNames.contains { attributeName in
              guard let value = hit.attributes[attributeName] else {
                return true
              }
              return value.isEmpty
            }
          }
          .map(\.identifier)
      )
    )

    guard !incompleteIdentifiers.isEmpty else {
      return hits
    }

    let hydratedAssets = try client.stringIdentifiedAssets(
      identifiers: incompleteIdentifiers,
      attributeFilters: [],
      includeVectors: false,
      selectAttributes: selectedAttributes
    )
    let attributesByIdentifier = hydratedAssets.reduce(into: [String: [String: String]]()) {
      partialResult,
      asset in
      partialResult[asset.stringIdentifier] = asset.attributes.merging(
        partialResult[asset.stringIdentifier] ?? [:]
      ) { hydratedValue, existingValue in
        existingValue.isEmpty ? hydratedValue : existingValue
      }
    }

    return hits.map { hit in
      guard let hydratedAttributes = attributesByIdentifier[hit.identifier] else {
        return hit
      }

      let mergedAttributes = hydratedAttributes.merging(hit.attributes) { hydratedValue, hitValue in
        hitValue.isEmpty ? hydratedValue : hitValue
      }
      return VectorSearchHit(
        identifier: hit.identifier,
        score: hit.score,
        attributes: mergedAttributes
      )
    }
  }
}
