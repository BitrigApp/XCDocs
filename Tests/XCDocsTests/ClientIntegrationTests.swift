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
    func entryAppendsSectionContentForSymbols() async throws {
        guard #available(macOS 26, *) else { return }
        try await entryAppendsSectionContentForSymbolsOnSupportedOS()
    }

    @Test
    func entryAppendsSectionContentForArticles() async throws {
        guard #available(macOS 26, *) else { return }
        try await entryAppendsSectionContentForArticlesOnSupportedOS()
    }

    @Test
    func searchDoesNotReturnArticleSectionsSeparatelyWhenParentArticleIsPresent() async throws {
        guard #available(macOS 26, *) else { return }
        try await searchDoesNotReturnArticleSectionsSeparatelyWhenParentArticleIsPresentOnSupportedOS()
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
private func entryAppendsSectionContentForSymbolsOnSupportedOS() async throws {
    let client = Client()
    let result = try await client.entry(for: "/documentation/SwiftUI/Color")
    let content = try #require(result.content)

    #expect(content.contains("A representation of a color that adapts to a given context."))
    #expect(content.contains("Color: Creating a color"))
    #expect(content.contains("Color: Getting standard colors"))
}

@available(macOS 26, *)
private func entryAppendsSectionContentForArticlesOnSupportedOS() async throws {
    let client = Client()
    let result = try await client.entry(for: LiveEnvironment.articleWithSectionsIdentifier)
    let content = try #require(result.content)

    #expect(content.contains("Configure, combine, and morph views using Liquid Glass effects."))
    #expect(content.contains("Applying Liquid Glass to custom views: Apply and configure Liquid Glass effects"))
    #expect(
        content.contains("Applying Liquid Glass to custom views: Combine multiple views with Liquid Glass containers")
    )
    #expect(content.contains("Applying Liquid Glass to custom views: Morph Liquid Glass effects during transitions"))
}

@available(macOS 26, *)
private func searchDoesNotReturnArticleSectionsSeparatelyWhenParentArticleIsPresentOnSupportedOS() async throws {
    let client = Client()
    let results = try await client.search(LiveEnvironment.articleWithSectionsQuery, limit: 10, omitContent: false)
    let articleResult = try #require(results.first { $0.entry.id == LiveEnvironment.articleWithSectionsIdentifier })
    let articleContent = try #require(articleResult.entry.content)

    #expect(articleContent.contains("Applying Liquid Glass to custom views: Apply and configure Liquid Glass effects"))
    #expect(
        results.allSatisfy { result in
            result.entry.id == LiveEnvironment.articleWithSectionsIdentifier
                || !result.entry.id.hasPrefix("\(LiveEnvironment.articleWithSectionsIdentifier)#")
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
