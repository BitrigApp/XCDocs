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
    let response = try await client.search(
      SearchRequest(
        query: LiveEnvironment.searchQuery,
        maxResults: 3
      )
    )

    #expect(response.query == LiveEnvironment.searchQuery)
    #expect(!response.results.isEmpty)
  }

  @Test
  func frameworkFilteringWorksEndToEnd() async throws {
    let response = try await client.search(
      SearchRequest(
        query: LiveEnvironment.searchQuery,
        frameworks: [LiveEnvironment.searchFramework],
        maxResults: 5
      )
    )

    #expect(!response.results.isEmpty)
    #expect(response.results.allSatisfy { $0.framework == LiveEnvironment.searchFramework })
  }

  @Test
  func kindFilteringWorksEndToEnd() async throws {
    let response = try await client.search(
      SearchRequest(
        query: LiveEnvironment.searchQuery,
        kinds: [.article],
        maxResults: 5
      )
    )

    #expect(!response.results.isEmpty)
    #expect(response.results.allSatisfy { $0.kind == .article })
  }

  @Test
  func includeContentIsReflectedInMappedSearchResults() async throws {
    let withoutContent = try await client.search(
      SearchRequest(
        query: "swiftui color",
        maxResults: 5,
        includeContent: false
      )
    )
    let withContent = try await client.search(
      SearchRequest(
        query: "swiftui color",
        maxResults: 5,
        includeContent: true
      )
    )

    #expect(withoutContent.results.allSatisfy { $0.content == nil })
    #expect(withContent.results.contains { !(($0.content ?? "").isEmpty) })
  }

  @Test
  func fetchReturnsExpectedMetadataAndContent() throws {
    let response = try client.fetch(
      FetchRequest(identifier: LiveEnvironment.documentationIdentifier)
    )

    #expect(response.result.identifier == LiveEnvironment.documentationIdentifier)
    #expect(response.result.framework == LiveEnvironment.searchFramework)
    #expect(!(response.result.title ?? "").isEmpty)
    #expect(!(response.result.content ?? "").isEmpty)
  }

  @Test
  func missingIdentifiersThrowAssetNotFoundBridgeErrors() throws {
    let error = try #require(
      captureBridgeError {
        try client.fetch(FetchRequest(identifier: "/documentation/DefinitelyNotReal"))
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
