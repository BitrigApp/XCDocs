import Foundation
import TestSupport
import Testing

@testable import XCDocsSupport

@Suite("VectorSearchClient Integration", .enabled(if: LiveEnvironment.isAvailable), .serialized)
struct VectorSearchClientIntegrationTests {
    @Test
    func fetchReturnsTheExpectedEntry() async throws {
        let client = try await makeClient()
        let hit = try await client.fetch(identifier: LiveEnvironment.documentationIdentifier)

        #expect(hit.identifier == LiveEnvironment.documentationIdentifier)
        #expect(hit.framework == LiveEnvironment.searchFramework)
        #expect(!(hit.title ?? "").isEmpty)
    }

    @Test
    func searchReturnsResultsForALiveEmbeddingVector() async throws {
        let client = try await makeClient()
        let vector = try await LiveEnvironment.embeddingVector(for: LiveEnvironment.searchQuery)
        let hits = try await client.search(vector: vector, frameworks: [], kinds: [], limit: 3, omitContent: true)

        #expect(!hits.isEmpty)
    }

    @Test
    func normalizesAndAppliesFrameworkFilters() async throws {
        let client = try await makeClient()
        let vector = try await LiveEnvironment.embeddingVector(for: LiveEnvironment.searchQuery)
        let hits = try await client.search(
            vector: vector,
            frameworks: ["  \(LiveEnvironment.searchFramework)  ", "", "   "],
            kinds: [],
            limit: 5,
            omitContent: true
        )

        #expect(!hits.isEmpty)
        #expect(hits.allSatisfy { $0.framework == LiveEnvironment.searchFramework })
    }

    @Test
    func normalizesAndAppliesKindFilters() async throws {
        let client = try await makeClient()
        let vector = try await LiveEnvironment.embeddingVector(for: LiveEnvironment.searchQuery)
        let hits = try await client.search(
            vector: vector,
            frameworks: [],
            kinds: ["  article  ", "", "   "],
            limit: 5,
            omitContent: true
        )

        #expect(!hits.isEmpty)
        #expect(hits.allSatisfy { $0.type == "article" })
    }

    @Test
    func omitContentControlsWhetherSearchResultsContainContent() async throws {
        let client = try await makeClient()
        let vector = try await LiveEnvironment.embeddingVector(for: "swiftui color")
        let hitsWithoutContent = try await client.search(
            vector: vector,
            frameworks: [],
            kinds: [],
            limit: 5,
            omitContent: true
        )
        let hitsWithContent = try await client.search(
            vector: vector,
            frameworks: [],
            kinds: [],
            limit: 5,
            omitContent: false
        )

        #expect(hitsWithoutContent.allSatisfy { $0.content == nil })
        #expect(hitsWithContent.contains { !(($0.content ?? "").isEmpty) })
    }

    @Test
    func returnsAnEmptyArrayWhenLimitIsZeroOrLess() async throws {
        let client = try await makeClient()
        let hits = try await client.search(
            vector: Data(),
            frameworks: [LiveEnvironment.searchFramework],
            kinds: ["article"],
            limit: 0,
            omitContent: true
        )

        #expect(hits.isEmpty)
    }

    private func makeClient() async throws -> VectorSearchClient {
        try await VectorSearchClient(databaseDirectoryURL: LiveEnvironment.databaseDirectoryURL(), readOnly: true)
    }
}
