import Foundation
import TestSupport
import Testing
import XCDocs

@testable import XCDocsBridge

@Suite("XCDocs Client Integration", .enabled(if: LiveEnvironment.isAvailable), .serialized)
struct ClientIntegrationTests {
  private let client = Client()

  @Test
  func searchReturnsResultsForALiveQuery() async throws {
    let results = try await client.search(
      LiveEnvironment.searchQuery,
      maxResults: 3
    )

    #expect(!results.isEmpty)
  }

  @Test
  func frameworkFilteringWorksEndToEnd() async throws {
    let results = try await client.search(
      LiveEnvironment.searchQuery,
      frameworks: [LiveEnvironment.searchFramework],
      maxResults: 5
    )

    #expect(!results.isEmpty)
    #expect(results.allSatisfy { $0.framework == LiveEnvironment.searchFramework })
  }

  @Test
  func kindFilteringWorksEndToEnd() async throws {
    let results = try await client.search(
      LiveEnvironment.searchQuery,
      kinds: [.article],
      maxResults: 5
    )

    #expect(!results.isEmpty)
    #expect(results.allSatisfy { $0.kind == .article })
  }

  @Test
  func includeContentIsReflectedInMappedSearchResults() async throws {
    let withoutContent = try await client.search(
      "swiftui color",
      maxResults: 5,
      includeContent: false
    )
    let withContent = try await client.search(
      "swiftui color",
      maxResults: 5,
      includeContent: true
    )

    #expect(withoutContent.allSatisfy { $0.content == nil })
    #expect(withContent.contains { !(($0.content ?? "").isEmpty) })
  }

  @Test
  func fetchReturnsExpectedMetadataAndContent() throws {
    let result = try client.fetch(LiveEnvironment.documentationIdentifier)

    #expect(result.identifier == LiveEnvironment.documentationIdentifier)
    #expect(result.framework == LiveEnvironment.searchFramework)
    #expect(!(result.title ?? "").isEmpty)
    #expect(!(result.content ?? "").isEmpty)
  }

  @Test
  func missingIdentifiersThrowAssetNotFoundBridgeErrors() throws {
    let error = try #require(
      captureBridgeError {
        try client.fetch("/documentation/DefinitelyNotReal")
      })

    #expect(error.code == .assetNotFound)
    #expect(error.message.contains("/documentation/DefinitelyNotReal"))
  }
}

private func captureBridgeError<T>(_ work: () throws -> T) -> BridgeError? {
  do {
    _ = try work()
    Issue.record("Expected BridgeError to be thrown.")
    return nil
  } catch let error as BridgeError {
    return error
  } catch {
    Issue.record("Unexpected error: \(String(describing: error))")
    return nil
  }
}
