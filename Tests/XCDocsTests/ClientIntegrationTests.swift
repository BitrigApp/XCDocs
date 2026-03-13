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
    func includeContentIsReflectedInMappedSearchResults() async throws {
        guard #available(macOS 26, *) else { return }
        try await includeContentIsReflectedInMappedSearchResultsOnSupportedOS()
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
    let results = try await client.search(LiveEnvironment.searchQuery, maxResults: 3)

    #expect(!results.isEmpty)
}

@available(macOS 26, *)
private func frameworkFilteringWorksEndToEndOnSupportedOS() async throws {
    let client = Client()
    let results = try await client.search(
        LiveEnvironment.searchQuery,
        frameworks: [LiveEnvironment.searchFramework],
        maxResults: 5
    )

    #expect(!results.isEmpty)
    #expect(results.allSatisfy { $0.framework == LiveEnvironment.searchFramework })
}

@available(macOS 26, *)
private func kindFilteringWorksEndToEndOnSupportedOS() async throws {
    let client = Client()
    let results = try await client.search(LiveEnvironment.searchQuery, kinds: [.article], maxResults: 5)

    #expect(!results.isEmpty)
    #expect(results.allSatisfy { $0.kind == .article })
}

@available(macOS 26, *)
private func includeContentIsReflectedInMappedSearchResultsOnSupportedOS() async throws {
    let client = Client()
    let withoutContent = try await client.search("swiftui color", maxResults: 5, includeContent: false)
    let withContent = try await client.search("swiftui color", maxResults: 5, includeContent: true)

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

private func captureBridgeError<T>(_ work: () throws -> T) -> BridgeError? {
    do {
        _ = try work()
        Issue.record("Expected BridgeError to be thrown.")
        return nil
    } catch let error as BridgeError { return error } catch {
        Issue.record("Unexpected error: \(String(describing: error))")
        return nil
    }
}
