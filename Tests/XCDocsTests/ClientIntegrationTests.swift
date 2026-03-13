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
    func entryReturnsExpectedMetadataAndContent() async throws {
        guard #available(macOS 26, *) else { return }
        try await entryReturnsExpectedMetadataAndContentOnSupportedOS()
    }

    @Test
    func entryAppendsSubtopicContentForCollectionGroupArticles() async throws {
        guard #available(macOS 26, *) else { return }
        try await entryAppendsSubtopicContentForCollectionGroupArticlesOnSupportedOS()
    }

    @Test
    func searchDoesNotReturnArticleSubtopicsSeparatelyWhenParentArticleIsPresent() async throws {
        guard #available(macOS 26, *) else { return }
        try await searchDoesNotReturnArticleSubtopicsSeparatelyWhenParentArticleIsPresentOnSupportedOS()
    }

    @Test
    func missingIdentifiersThrowAssetNotFoundBridgeErrors() async throws {
        guard #available(macOS 26, *) else { return }
        try await missingIdentifiersThrowAssetNotFoundBridgeErrorsOnSupportedOS()
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
    #expect(results.allSatisfy { $0.entry.framework == LiveEnvironment.searchFramework })
}

@available(macOS 26, *)
private func kindFilteringWorksEndToEndOnSupportedOS() async throws {
    let client = Client()
    let results = try await client.search(LiveEnvironment.searchQuery, kinds: [.article], limit: 5)

    #expect(!results.isEmpty)
    #expect(results.allSatisfy { $0.entry.kind == .article })
}

@available(macOS 26, *)
private func omitContentIsReflectedInMappedSearchResultsOnSupportedOS() async throws {
    let client = Client()
    let withoutContent = try await client.search("swiftui color", limit: 5, omitContent: true)
    let withContent = try await client.search("swiftui color", limit: 5, omitContent: false)

    #expect(withoutContent.allSatisfy { $0.entry.content == nil })
    #expect(withContent.contains { !(($0.entry.content ?? "").isEmpty) })
}

@available(macOS 26, *)
private func entryReturnsExpectedMetadataAndContentOnSupportedOS() async throws {
    let client = Client()
    let result = try await client.entry(for: LiveEnvironment.documentationIdentifier)

    #expect(result.id == LiveEnvironment.documentationIdentifier)
    #expect(result.framework == LiveEnvironment.searchFramework)
    #expect(!(result.title ?? "").isEmpty)
    #expect(!(result.content ?? "").isEmpty)
}

@available(macOS 26, *)
private func entryAppendsSubtopicContentForCollectionGroupArticlesOnSupportedOS() async throws {
    let client = Client()
    let result = try await client.entry(for: LiveEnvironment.articleWithSubtopicsIdentifier)
    let content = try #require(result.content)

    #expect(content.contains("Learn how to design and develop beautiful interfaces that leverage Liquid Glass."))
    #expect(content.contains("Liquid Glass: Introduction to Liquid Glass"))
    #expect(content.contains("Liquid Glass: Adopting Liquid Glass"))
    #expect(content.contains("Liquid Glass: Essentials"))
}

@available(macOS 26, *)
private func searchDoesNotReturnArticleSubtopicsSeparatelyWhenParentArticleIsPresentOnSupportedOS() async throws {
    let client = Client()
    let results = try await client.search(LiveEnvironment.articleWithSubtopicsQuery, limit: 10, omitContent: false)
    let articleResult = try #require(results.first { $0.entry.id == LiveEnvironment.articleWithSubtopicsIdentifier })
    let articleContent = try #require(articleResult.entry.content)

    #expect(articleContent.contains("Liquid Glass: Introduction to Liquid Glass"))
    #expect(
        results.allSatisfy { result in
            result.entry.id == LiveEnvironment.articleWithSubtopicsIdentifier
                || !result.entry.id.hasPrefix("\(LiveEnvironment.articleWithSubtopicsIdentifier)#")
        }
    )
}

@available(macOS 26, *)
private func missingIdentifiersThrowAssetNotFoundBridgeErrorsOnSupportedOS() async throws {
    let client = Client()
    let error = try #require(
        await captureBridgeError { try await client.entry(for: "/documentation/DefinitelyNotReal") }
    )

    #expect(error.code == .assetNotFound)
    #expect(error.message.contains("/documentation/DefinitelyNotReal"))
}
