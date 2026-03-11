import Foundation
import Testing
import XCDocs

@Suite("XCDocs Models")
struct ModelTests {
  @Test
  func searchRequestUsesExpectedDefaultsAndValueSemantics() {
    let original = SearchRequest(query: "swift testing")
    var copy = original
    copy.frameworks = ["Swift Testing"]
    copy.maxResults = 3
    copy.includeContent = true

    #expect(original.frameworks.isEmpty)
    #expect(original.maxResults == 10)
    #expect(original.includeContent == false)
  }

  @Test
  func publicModelsRoundTripThroughCodable() throws {
    try assertRoundTrip(
      SearchRequest(
        query: "swift testing",
        frameworks: ["Swift Testing"],
        maxResults: 5,
        includeContent: true
      )
    )
    try assertRoundTrip(
      SearchResult(
        identifier: "/documentation/Testing",
        score: 0.75,
        framework: "Swift Testing",
        kind: "article",
        title: "Swift Testing",
        content: "Create and run tests."
      )
    )
    try assertRoundTrip(
      SearchResponse(
        query: "swift testing",
        results: [
          SearchResult(
            identifier: "/documentation/Testing",
            score: 0.75,
            framework: "Swift Testing",
            kind: "article",
            title: "Swift Testing",
            content: "Create and run tests."
          )
        ]
      )
    )
    try assertRoundTrip(FetchRequest(identifier: "/documentation/Testing"))
    try assertRoundTrip(
      FetchResult(
        identifier: "/documentation/Testing",
        framework: "Swift Testing",
        kind: "article",
        title: "Swift Testing",
        content: "Create and run tests."
      )
    )
    try assertRoundTrip(
      FetchResponse(
        result: FetchResult(
          identifier: "/documentation/Testing",
          framework: "Swift Testing",
          kind: "article",
          title: "Swift Testing",
          content: "Create and run tests."
        )
      )
    )
  }
}

private func assertRoundTrip<T: Codable & Equatable>(_ value: T) throws {
  let data = try JSONEncoder().encode(value)
  let decoded = try JSONDecoder().decode(T.self, from: data)
  #expect(decoded == value)
}
