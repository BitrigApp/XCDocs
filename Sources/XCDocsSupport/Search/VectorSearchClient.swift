import Foundation
import XCDocsBridge

package final class VectorSearchClient {
    private enum SearchConfiguration {
        static let numberOfProbes = 8
        static let batchSize = 64
        static let concurrentReaders = 2
    }

    private let client: VSKClientObject

    package init(databaseDirectoryURL: URL, readOnly: Bool) async throws {
        let config = try await VSKConfigObject(
            baseDirectoryURL: databaseDirectoryURL,
            numberOfProbes: SearchConfiguration.numberOfProbes,
            readOnly: readOnly
        )
        self.client = try await VSKClientObject(config: config)
    }

    package func search(vector: Data, frameworks: [String], kinds: [String], limit: Int, omitContent: Bool) async throws
        -> [VectorSearchHit]
    {
        guard limit > 0 else { return [] }

        let frameworkFilters = try await makeFilters(attributeName: "framework", values: frameworks)
        let kindFilters = try await makeFilters(attributeName: "type", values: kinds)
        let filters = frameworkFilters + kindFilters
        var selectedAttributes = [
            try await VSKAttributeObject.stringAttribute(named: "framework"),
            try await VSKAttributeObject.stringAttribute(named: "type"),
            try await VSKAttributeObject.stringAttribute(named: "title"),
        ]
        if !omitContent { selectedAttributes.append(try await VSKAttributeObject.stringAttribute(named: "content")) }

        let rawResults = try await client.search(
            vector: vector,
            identifiers: nil,
            attributeFilters: filters,
            selectedAttributes: selectedAttributes,
            limit: limit,
            fullScan: true,
            numberOfProbes: SearchConfiguration.numberOfProbes,
            batchSize: SearchConfiguration.batchSize,
            concurrentReaders: SearchConfiguration.concurrentReaders
        )

        var hits: [VectorSearchHit] = []
        hits.reserveCapacity(rawResults.count)
        for result in rawResults {
            hits.append(
                try await VectorSearchHit(
                    identifier: result.identifier,
                    score: result.score,
                    attributes: result.attributes
                )
            )
        }

        return try await hydrateSearchHits(hits, selectedAttributes: selectedAttributes)
    }

    package func entry(for identifier: String) async throws -> VectorSearchHit {
        let selectedAttributes = [
            try await VSKAttributeObject.stringAttribute(named: "framework"),
            try await VSKAttributeObject.stringAttribute(named: "type"),
            try await VSKAttributeObject.stringAttribute(named: "title"),
            try await VSKAttributeObject.stringAttribute(named: "content"),
        ]

        let asset = try await client.asset(
            forIdentifier: identifier,
            attributeFilters: [],
            includeVectors: false,
            selectedAttributes: selectedAttributes
        )

        return await VectorSearchHit(identifier: asset.identifier, score: .nan, attributes: asset.attributes)
    }

    // MARK: Private

    private func makeFilters(attributeName: String, values: [String]) async throws -> [VSKFilterObject] {
        let normalizedValues = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }

        guard !normalizedValues.isEmpty else { return [] }

        let attribute = try await VSKAttributeObject.stringAttribute(named: attributeName)
        var disjunctiveFilters: [VSKDisjunctiveFilterObject] = []
        disjunctiveFilters.reserveCapacity(normalizedValues.count)
        for value in normalizedValues {
            let databaseValue = try await VSKDatabaseValueObject(string: value)
            disjunctiveFilters.append(try await VSKDisjunctiveFilterObject(operator: .equals, value: databaseValue))
        }

        return [try await VSKFilterObject(attribute: attribute, disjunctiveFilters: disjunctiveFilters)]
    }

    private func hydrateSearchHits(_ hits: [VectorSearchHit], selectedAttributes: [VSKAttributeObject]) async throws
        -> [VectorSearchHit]
    {
        var attributeNames: [String] = []
        attributeNames.reserveCapacity(selectedAttributes.count)
        for attribute in selectedAttributes { attributeNames.append(await attribute.name) }
        let incompleteIdentifiers = Array(
            Set(
                hits.filter { hit in
                    attributeNames.contains { attributeName in
                        guard let value = hit.attributes[attributeName] else { return true }
                        return value.isEmpty
                    }
                }.map(\.identifier)
            )
        )

        guard !incompleteIdentifiers.isEmpty else { return hits }

        let hydratedAssets = try await client.assets(
            forIdentifiers: incompleteIdentifiers,
            attributeFilters: [],
            includeVectors: false,
            selectedAttributes: selectedAttributes
        )
        var attributesByIdentifier: [String: [String: String]] = [:]
        for asset in hydratedAssets {
            let identifier = await asset.identifier
            let attributes = await asset.attributes
            attributesByIdentifier[identifier] = attributes.merging(attributesByIdentifier[identifier] ?? [:]) {
                hydratedValue,
                existingValue in existingValue.isEmpty ? hydratedValue : existingValue
            }
        }

        return hits.map { hit in
            guard let hydratedAttributes = attributesByIdentifier[hit.identifier] else { return hit }

            let mergedAttributes = hydratedAttributes.merging(hit.attributes) { hydratedValue, hitValue in
                hitValue.isEmpty ? hydratedValue : hitValue
            }
            return VectorSearchHit(identifier: hit.identifier, score: hit.score, attributes: mergedAttributes)
        }
    }
}
