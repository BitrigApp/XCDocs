import Foundation
import Testing
import XCDocs

@testable import XCDocsCLI

@Suite("Search JSON Output")
struct SearchJSONOutputTests {
    @Test
    func searchDocumentEmitsNullForNilFields() throws {
        guard #available(macOS 26, *) else { return }
        try assertSearchDocumentEmitsNullForNilFields()
    }

    @Test
    func searchDocumentPreservesNonNilValues() throws {
        guard #available(macOS 26, *) else { return }
        try assertSearchDocumentPreservesNonNilValues()
    }
}

@available(macOS 26, *)
private func assertSearchDocumentEmitsNullForNilFields() throws {
    let entry = DocumentationEntry(id: "/documentation/Testing", framework: nil, kind: nil, title: nil, content: nil)
    let result = SearchResult(score: 0.5, entry: entry)

    let response = DocumentationSearchResponse(searchResults: [result])
    let data = try JSONEncoder().encode(response)
    let string = try #require(String(data: data, encoding: .utf8))
    let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let documents = try #require(json["documents"] as? [[String: Any]])
    let doc = try #require(documents.first)

    // nil fields must be encoded as JSON null, not coerced to empty strings or omitted.
    #expect(doc["title"] is NSNull, "Expected null for nil title, got \(String(describing: doc["title"]))")
    #expect(doc["contents"] is NSNull, "Expected null for nil contents, got \(String(describing: doc["contents"]))")
    #expect(!string.contains("\"title\":\"\""), "title should not be an empty string")
    #expect(!string.contains("\"contents\":\"\""), "contents should not be an empty string")
    #expect(doc["uri"] as? String == "/documentation/Testing")
    #expect(doc["score"] as? Double == 0.5)
}

@available(macOS 26, *)
private func assertSearchDocumentPreservesNonNilValues() throws {
    let entry = DocumentationEntry(
        id: "/documentation/Testing",
        framework: "Swift Testing",
        kind: .article,
        title: "Swift Testing",
        content: "Create and run tests."
    )
    let result = SearchResult(score: 0.75, entry: entry)

    let response = DocumentationSearchResponse(searchResults: [result])
    let data = try JSONEncoder().encode(response)
    let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let documents = try #require(json["documents"] as? [[String: Any]])
    let doc = try #require(documents.first)

    #expect(doc["title"] as? String == "Swift Testing")
    #expect(doc["contents"] as? String == "Create and run tests.")
    #expect(doc["uri"] as? String == "/documentation/Testing")
    #expect(doc["score"] as? Double == 0.75)
}
