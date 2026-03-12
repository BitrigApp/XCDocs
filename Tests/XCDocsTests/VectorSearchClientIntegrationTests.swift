import Foundation
import TestSupport
import Testing

@testable import XCDocsSupport

@Suite("VectorSearchClient Integration", .enabled(if: LiveEnvironment.isAvailable), .serialized)
struct VectorSearchClientIntegrationTests {
    @Test func fetchReturnsTheExpectedEntry() throws {
        let client = try makeClient()
        let hit = try #require(try client.fetch(identifier: LiveEnvironment.documentationIdentifier))

        #expect(hit.identifier == LiveEnvironment.documentationIdentifier)
        #expect(hit.framework == LiveEnvironment.searchFramework)
        #expect(!(hit.title ?? "").isEmpty)
    }

    @Test func searchReturnsResultsForALiveEmbeddingVector() async throws {
        let client = try makeClient()
        let vector = try await LiveEnvironment.embeddingVector(for: LiveEnvironment.searchQuery)
        let hits = try client.search(vector: vector, frameworks: [], kinds: [], limit: 3, includeContent: false)

        #expect(!hits.isEmpty)
    }

    @Test func normalizesAndAppliesFrameworkFilters() async throws {
        let client = try makeClient()
        let vector = try await LiveEnvironment.embeddingVector(for: LiveEnvironment.searchQuery)
        let hits = try client.search(
            vector: vector,
            frameworks: ["  \(LiveEnvironment.searchFramework)  ", "", "   "],
            kinds: [],
            limit: 5,
            includeContent: false
        )

        #expect(!hits.isEmpty)
        #expect(hits.allSatisfy { $0.framework == LiveEnvironment.searchFramework })
    }

    @Test func normalizesAndAppliesKindFilters() async throws {
        let client = try makeClient()
        let vector = try await LiveEnvironment.embeddingVector(for: LiveEnvironment.searchQuery)
        let hits = try client.search(
            vector: vector,
            frameworks: [],
            kinds: ["  article  ", "", "   "],
            limit: 5,
            includeContent: false
        )

        #expect(!hits.isEmpty)
        #expect(hits.allSatisfy { $0.type == "article" })
    }

    @Test func includeContentControlsWhetherSearchResultsContainContent() async throws {
        let client = try makeClient()
        let vector = try await LiveEnvironment.embeddingVector(for: "swiftui color")
        let hitsWithoutContent = try client.search(
            vector: vector,
            frameworks: [],
            kinds: [],
            limit: 5,
            includeContent: false
        )
        let hitsWithContent = try client.search(
            vector: vector,
            frameworks: [],
            kinds: [],
            limit: 5,
            includeContent: true
        )

        #expect(hitsWithoutContent.allSatisfy { $0.content == nil })
        #expect(hitsWithContent.contains { !(($0.content ?? "").isEmpty) })
    }

    @Test func returnsAnEmptyArrayWhenLimitIsZeroOrLess() throws {
        let client = try makeClient()
        let hits = try client.search(
            vector: Data(),
            frameworks: [LiveEnvironment.searchFramework],
            kinds: ["article"],
            limit: 0,
            includeContent: false
        )

        #expect(hits.isEmpty)
    }

    private func makeClient() throws -> VectorSearchClient {
        try VectorSearchClient(databaseDirectoryURL: LiveEnvironment.databaseDirectoryURL(), readOnly: true)
    }
}
