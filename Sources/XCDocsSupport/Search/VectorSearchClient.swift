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
                VectorSearchHit(
                    identifier: await result.identifier,
                    score: try await result.score,
                    attributes: await result.attributes
                )
            )
        }

        let hydratedHits = try await hydrateSearchHits(hits, selectedAttributes: selectedAttributes)
        let descendantsByParent = try await descendantIdentifiersByParent(in: hydratedHits)
        let contentExpandedHits: [VectorSearchHit]
        if omitContent {
            contentExpandedHits = hydratedHits
        } else {
            contentExpandedHits = try await appendDescendantContents(
                to: hydratedHits,
                descendantsByParent: descendantsByParent,
                selectedAttributes: selectedAttributes
            )
        }

        return deduplicateSearchHits(contentExpandedHits, descendantsByParent: descendantsByParent)
    }

    package func entry(for identifier: String) async throws -> VectorSearchHit {
        let selectedAttributes = try await exactLookupAttributes()
        let asset = try await client.asset(
            forIdentifier: identifier,
            attributeFilters: [],
            includeVectors: false,
            selectedAttributes: selectedAttributes
        )
        let hit = VectorSearchHit(identifier: await asset.identifier, score: .nan, attributes: await asset.attributes)

        let descendantsByParent = try await descendantIdentifiersByParent(forParentIdentifiers: [identifier])
        guard descendantsByParent[identifier] != nil else { return hit }
        let expandedHits = try await appendDescendantContents(
            to: [hit],
            descendantsByParent: descendantsByParent,
            selectedAttributes: selectedAttributes
        )
        return expandedHits[0]
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

    private func fetchHits(for identifiers: [String], selectedAttributes: [VSKAttributeObject]) async throws
        -> [VectorSearchHit]
    {
        guard !identifiers.isEmpty else { return [] }

        let uniqueIdentifiers = orderedUniqueIdentifiers(from: identifiers)
        let assets = try await client.assets(
            forIdentifiers: uniqueIdentifiers,
            attributeFilters: [],
            includeVectors: false,
            selectedAttributes: selectedAttributes
        )
        var hitsByIdentifier: [String: VectorSearchHit] = [:]
        hitsByIdentifier.reserveCapacity(assets.count)
        for asset in assets {
            let identifier = await asset.identifier
            let attributes = await asset.attributes
            hitsByIdentifier[identifier] = VectorSearchHit(identifier: identifier, score: .nan, attributes: attributes)
        }

        for identifier in uniqueIdentifiers where hitsByIdentifier[identifier] == nil {
            throw missingEntryError(for: identifier)
        }

        return try identifiers.map { identifier in
            guard let hit = hitsByIdentifier[identifier] else { throw missingEntryError(for: identifier) }
            return hit
        }
    }

    private func descendantIdentifiersByParent(in hits: [VectorSearchHit]) async throws -> [String: [String]] {
        try await descendantIdentifiersByParent(
            forParentIdentifiers: hits.map(\.identifier).filter { !$0.contains("#") }
        )
    }

    private func descendantIdentifiersByParent(forParentIdentifiers identifiers: [String]) async throws -> [String:
        [String]]
    {
        let parentIdentifiers = orderedUniqueIdentifiers(from: identifiers.filter { !$0.contains("#") })
        guard !parentIdentifiers.isEmpty else { return [:] }

        let topicIdentifiers = try await topicIdentifiers()
        guard !topicIdentifiers.isEmpty else { return [:] }

        var descendantsByParent: [String: [String]] = [:]
        descendantsByParent.reserveCapacity(parentIdentifiers.count)
        for parentIdentifier in parentIdentifiers {
            let descendantPrefix = "\(parentIdentifier)#"
            let descendants = topicIdentifiers.filter { $0.hasPrefix(descendantPrefix) }
            if !descendants.isEmpty { descendantsByParent[parentIdentifier] = descendants }
        }

        return descendantsByParent
    }

    private func topicIdentifiers() async throws -> [String] {
        orderedUniqueIdentifiers(
            from: try await client.stringIdentifiers(
                applying: try await makeFilters(attributeName: "type", values: ["topic"])
            )
        )
    }

    private func appendDescendantContents(
        to hits: [VectorSearchHit],
        descendantsByParent: [String: [String]],
        selectedAttributes: [VSKAttributeObject]
    ) async throws -> [VectorSearchHit] {
        let descendantIdentifiers = orderedUniqueIdentifiers(from: descendantsByParent.values.flatMap { $0 })
        guard !descendantIdentifiers.isEmpty else { return hits }

        let descendantHits = try await fetchHits(for: descendantIdentifiers, selectedAttributes: selectedAttributes)
        let descendantContentByIdentifier: [String: String] = Dictionary(
            uniqueKeysWithValues: descendantHits.compactMap { hit in
                guard let content = hit.content else { return nil }
                return (hit.identifier, content)
            }
        )

        return hits.map { hit in
            guard let descendantIdentifiers = descendantsByParent[hit.identifier], !descendantIdentifiers.isEmpty else {
                return hit
            }

            let descendantContents = descendantIdentifiers.compactMap { identifier -> String? in
                guard let content = descendantContentByIdentifier[identifier], !content.isEmpty else { return nil }
                return content
            }
            guard !descendantContents.isEmpty else { return hit }

            let joinedContent = ([hit.content].compactMap { $0 }.filter { !$0.isEmpty } + descendantContents).joined(
                separator: "\n\n"
            )
            var attributes = hit.attributes
            attributes["content"] = joinedContent
            return VectorSearchHit(identifier: hit.identifier, score: hit.score, attributes: attributes)
        }
    }

    private func deduplicateSearchHits(_ hits: [VectorSearchHit], descendantsByParent: [String: [String]])
        -> [VectorSearchHit]
    {
        let descendantIdentifiers = Set(descendantsByParent.values.flatMap { $0 })
        guard !descendantIdentifiers.isEmpty else { return hits }
        return hits.filter { !descendantIdentifiers.contains($0.identifier) }
    }

    private func exactLookupAttributes() async throws -> [VSKAttributeObject] {
        [
            try await VSKAttributeObject.stringAttribute(named: "framework"),
            try await VSKAttributeObject.stringAttribute(named: "type"),
            try await VSKAttributeObject.stringAttribute(named: "title"),
            try await VSKAttributeObject.stringAttribute(named: "content"),
        ]
    }

    private func missingEntryError(for identifier: String) -> NSError {
        NSError(
            domain: "XCDocsSupport.VectorSearchClient",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "No documentation entry was found for \(identifier)"]
        )
    }

    private func orderedUniqueIdentifiers(from identifiers: [String]) -> [String] {
        var seen: Set<String> = []
        var uniqueIdentifiers: [String] = []
        uniqueIdentifiers.reserveCapacity(identifiers.count)

        for identifier in identifiers where seen.insert(identifier).inserted { uniqueIdentifiers.append(identifier) }

        return uniqueIdentifiers
    }
}
