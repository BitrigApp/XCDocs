import Foundation
import TestSupport
import Testing
import XCDocs

@testable import XCDocsBridge

@Suite("XCDocs Client Integration", .enabled(if: LiveEnvironment.isAvailable), .serialized)
struct ClientIntegrationTests {
    @Test
    func searchReturnsResultsForALiveQuery() async throws {
        guard #available(macOS 26, *) else { return }
        try await searchReturnsResultsForALiveQueryOnSupportedOS()
    }

    @Test
    func frameworkFilteringWorksEndToEnd() async throws {
        guard #available(macOS 26, *) else { return }
        try await frameworkFilteringWorksEndToEndOnSupportedOS()
    }

    @Test
    func kindFilteringWorksEndToEnd() async throws {
        guard #available(macOS 26, *) else { return }
        try await kindFilteringWorksEndToEndOnSupportedOS()
    }

    @Test
    func omitContentIsReflectedInMappedSearchResults() async throws {
        guard #available(macOS 26, *) else { return }
        try await omitContentIsReflectedInMappedSearchResultsOnSupportedOS()
    }

    @Test
    func fetchReturnsExpectedMetadataAndContent() throws {
        guard #available(macOS 26, *) else { return }
        try fetchReturnsExpectedMetadataAndContentOnSupportedOS()
    }

    @Test
    func missingIdentifiersThrowAssetNotFoundBridgeErrors() throws {
        guard #available(macOS 26, *) else { return }
        try missingIdentifiersThrowAssetNotFoundBridgeErrorsOnSupportedOS()
    }
}

@available(macOS 26, *)
private func searchReturnsResultsForALiveQueryOnSupportedOS() async throws {
    let client = Client()
    let results = try await client.search(LiveEnvironment.searchQuery, limit: 3)

    #expect(!results.isEmpty)
}

@available(macOS 26, *)
private func frameworkFilteringWorksEndToEndOnSupportedOS() async throws {
    let client = Client()
    let results = try await client.search(
        LiveEnvironment.searchQuery,
        frameworks: [LiveEnvironment.searchFramework],
        limit: 5
    )

    #expect(!results.isEmpty)
    #expect(results.allSatisfy { $0.framework == LiveEnvironment.searchFramework })
}

@available(macOS 26, *)
private func kindFilteringWorksEndToEndOnSupportedOS() async throws {
    let client = Client()
    let results = try await client.search(LiveEnvironment.searchQuery, kinds: [.article], limit: 5)

    #expect(!results.isEmpty)
    #expect(results.allSatisfy { $0.kind == .article })
}

@available(macOS 26, *)
private func omitContentIsReflectedInMappedSearchResultsOnSupportedOS() async throws {
    let client = Client()
    let withoutContent = try await client.search("swiftui color", limit: 5, omitContent: true)
    let withContent = try await client.search("swiftui color", limit: 5, omitContent: false)

    #expect(withoutContent.allSatisfy { $0.content == nil })
    #expect(withContent.contains { !(($0.content ?? "").isEmpty) })
}

@available(macOS 26, *)
private func fetchReturnsExpectedMetadataAndContentOnSupportedOS() throws {
    let client = Client()
    let result = try client.fetch(LiveEnvironment.documentationIdentifier)

    #expect(result.identifier == LiveEnvironment.documentationIdentifier)
    #expect(result.framework == LiveEnvironment.searchFramework)
    #expect(!(result.title ?? "").isEmpty)
    #expect(!(result.content ?? "").isEmpty)
}

@available(macOS 26, *)
private func missingIdentifiersThrowAssetNotFoundBridgeErrorsOnSupportedOS() throws {
    let client = Client()
    let error = try #require(captureBridgeError { try client.fetch("/documentation/DefinitelyNotReal") })

    #expect(error.code == .assetNotFound)
    #expect(error.message.contains("/documentation/DefinitelyNotReal"))
}
