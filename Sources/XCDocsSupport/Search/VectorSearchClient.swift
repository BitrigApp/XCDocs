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
        let hit = VectorSearchHit(
            identifier: await asset.identifier,
            score: .nan,
            attributes: await attributes(of: asset, includingContent: true)
        )

        let descendantsByParent = try await descendantIdentifiersByParent(in: [hit])
        guard descendantsByParent[hit.identifier] != nil else { return hit }
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
        let attributeNames = await names(of: selectedAttributes)
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
        let includesContent = attributeNames.contains("content")
        var attributesByIdentifier: [String: [String: String]] = [:]
        for asset in hydratedAssets {
            let identifier = await asset.identifier
            let attributes = await attributes(of: asset, includingContent: includesContent)
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
        let includesContent = await names(of: selectedAttributes).contains("content")
        var hitsByIdentifier: [String: VectorSearchHit] = [:]
        hitsByIdentifier.reserveCapacity(assets.count)
        for asset in assets {
            let identifier = await asset.identifier
            let attributes = await attributes(of: asset, includingContent: includesContent)
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
        let parents = hits.filter { !$0.identifier.contains("#") }
        let parentIdentifiers = orderedUniqueIdentifiers(from: parents.map(\.identifier))
        guard !parentIdentifiers.isEmpty else { return [:] }

        // Sections share their page's framework, so a page without one leaves no framework to narrow the lookup by.
        let frameworks = parents.contains { ($0.framework ?? "").isEmpty } ? [] : parents.compactMap(\.framework)
        let sectionIdentifiers = try await sectionIdentifiers(inFrameworks: Array(Set(frameworks)))
        guard !sectionIdentifiers.isEmpty else { return [:] }

        var descendantsByParent: [String: [String]] = [:]
        descendantsByParent.reserveCapacity(parentIdentifiers.count)
        for parentIdentifier in parentIdentifiers {
            let descendantPrefix = "\(parentIdentifier)#"
            let descendants = sectionIdentifiers.filter { $0.hasPrefix(descendantPrefix) }
            if !descendants.isEmpty { descendantsByParent[parentIdentifier] = descendants }
        }

        return descendantsByParent
    }

    /// Returns the identifiers of the page sections in the given frameworks, or in all frameworks if none are given,
    /// in document order.
    ///
    /// Older documentation assets store only topic groups as separate `page#section` entries. Assets built for
    /// Xcode 27 split every page into sections, typed like the page itself, and keep only the overview on the page.
    private func sectionIdentifiers(inFrameworks frameworks: [String]) async throws -> [String] {
        let identifiers = try await client.stringIdentifiers(
            applying: try await makeFilters(attributeName: "framework", values: frameworks)
        )
        return orderedUniqueIdentifiers(from: identifiers.filter { $0.contains("#") })
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

    /// Returns an asset's attributes, taking `content` from the asset's payload when the attribute is empty.
    ///
    /// Documentation assets built for Xcode 27 leave the `content` attribute empty and store each page's text in a
    /// JSON payload instead.
    private func attributes(of asset: VSKAssetObject, includingContent includesContent: Bool) async -> [String: String]
    {
        var attributes = await asset.attributes
        guard includesContent, attributes["content"]?.isEmpty ?? true, let payload = await asset.payload,
            let content = try? JSONDecoder().decode(DocumentPayload.self, from: payload).content
        else { return attributes }

        attributes["content"] = content
        return attributes
    }

    private func names(of attributes: [VSKAttributeObject]) async -> [String] {
        var names: [String] = []
        names.reserveCapacity(attributes.count)
        for attribute in attributes { names.append(await attribute.name) }
        return names
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

/// The JSON document a documentation asset stores as its payload.
private struct DocumentPayload: Decodable { let content: String? }
