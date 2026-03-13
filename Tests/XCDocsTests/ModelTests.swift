import Foundation
import Testing
import XCDocs

@Suite("XCDocs Models")
struct ModelTests {
    @Test
    func publicModelsRoundTripThroughCodable() throws {
        guard #available(macOS 26, *) else { return }
        try publicModelsRoundTripThroughCodableOnSupportedOS()
    }

    @Test
    func allDocumentationKindCasesRoundTripThroughCodable() throws {
        guard #available(macOS 26, *) else { return }
        try allDocumentationKindCasesRoundTrip()
    }

    @Test
    func searchResultHandlesEmptyAndSpecialCharacterFields() throws {
        guard #available(macOS 26, *) else { return }
        try searchResultWithEmptyAndSpecialFields()
    }

    @Test
    func documentationEntryHandlesEmptyAndSpecialCharacterFields() throws {
        guard #available(macOS 26, *) else { return }
        try documentationEntryWithEmptyAndSpecialFields()
    }

    @Test
    func searchResultEncodesEntryWithoutDuplicatingEntryFields() throws {
        guard #available(macOS 26, *) else { return }
        try searchResultEncodesNestedEntryShape()
    }

    @Test
    func publicModelsExposeStableIdentities() throws {
        guard #available(macOS 26, *) else { return }
        assertStableIdentities()
    }

    @Test
    func documentationEntryDecodesUnknownKindAsNil() throws {
        guard #available(macOS 26, *) else { return }
        try assertUnknownKindDecodesAsNil()
    }

    @Test
    func searchResultWithNaNScoreThrowsOnJSONEncode() throws {
        guard #available(macOS 26, *) else { return }
        assertNaNScoreThrowsOnEncode()
    }

    @Test
    func searchResultWithInfinityScoreThrowsOnJSONEncode() throws {
        guard #available(macOS 26, *) else { return }
        assertInfinityScoreThrowsOnEncode()
    }
}

@available(macOS 26, *)
private func publicModelsRoundTripThroughCodableOnSupportedOS() throws {
    try assertRoundTrip(DocumentationKind.article)
    try assertRoundTrip(
        SearchResult(
            score: 0.75,
            entry: DocumentationEntry(
                id: "/documentation/Testing",
                framework: "Swift Testing",
                kind: .article,
                title: "Swift Testing",
                content: "Create and run tests."
            )
        )
    )
    try assertRoundTrip(
        DocumentationEntry(
            id: "/documentation/Testing",
            framework: "Swift Testing",
            kind: .article,
            title: "Swift Testing",
            content: "Create and run tests."
        )
    )
}

@available(macOS 26, *)
private func allDocumentationKindCasesRoundTrip() throws {
    for kind in DocumentationKind.allCases { try assertRoundTrip(kind) }
}

@available(macOS 26, *)
private func searchResultWithEmptyAndSpecialFields() throws {
    try assertRoundTrip(
        SearchResult(score: 0.0, entry: DocumentationEntry(id: "", framework: nil, kind: nil, title: nil, content: nil))
    )
    try assertRoundTrip(
        SearchResult(
            score: -1.0,
            entry: DocumentationEntry(
                id: "/docs/special/<chars>&\"quotes\"",
                framework: "",
                kind: .symbol,
                title: "Title with emoji \u{1F600} and newline\n",
                content: "Content with tabs\tand unicode \u{00E9}\u{00F1}"
            )
        )
    )
}

@available(macOS 26, *)
private func documentationEntryWithEmptyAndSpecialFields() throws {
    try assertRoundTrip(DocumentationEntry(id: "", framework: nil, kind: nil, title: nil, content: nil))
    try assertRoundTrip(
        DocumentationEntry(
            id: "/docs/special/<chars>&\"quotes\"",
            framework: "",
            kind: .topic,
            title: "Title with emoji \u{1F600} and newline\n",
            content: "Content with tabs\tand unicode \u{00E9}\u{00F1}"
        )
    )
}

@available(macOS 26, *)
private func searchResultEncodesNestedEntryShape() throws {
    let result = SearchResult(
        score: 0.75,
        entry: DocumentationEntry(
            id: "/documentation/Testing",
            framework: "Swift Testing",
            kind: .article,
            title: "Swift Testing",
            content: "Create and run tests."
        )
    )

    let data = try JSONEncoder().encode(result)
    let jsonObject = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

    #expect(jsonObject["score"] as? NSNumber == 0.75)
    #expect(jsonObject["entry"] as? [String: Any] != nil)
    #expect(jsonObject["identifier"] == nil)
    #expect((jsonObject["entry"] as? [String: Any])?["id"] as? String == "/documentation/Testing")
    #expect((jsonObject["entry"] as? [String: Any])?["identifier"] == nil)
    #expect(jsonObject["framework"] == nil)
    #expect(jsonObject["kind"] == nil)
    #expect(jsonObject["title"] == nil)
    #expect(jsonObject["content"] == nil)
}

@available(macOS 26, *)
private func assertStableIdentities() {
    let entry = DocumentationEntry(
        id: "/documentation/Testing",
        framework: "Swift Testing",
        kind: .article,
        title: "Swift Testing",
        content: "Create and run tests."
    )
    let result = SearchResult(score: 0.75, entry: entry)

    #expect(entry.id == "/documentation/Testing")
    #expect(result.id == entry.id)
}

@available(macOS 26, *)
private func assertUnknownKindDecodesAsNil() throws {
    let json = """
        {"id":"/doc/X","framework":null,"kind":"unknownKind","title":null,"content":null}
        """
    let entry = try JSONDecoder().decode(DocumentationEntry.self, from: Data(json.utf8))
    #expect(entry.kind == nil)
}

@available(macOS 26, *)
private func assertNaNScoreThrowsOnEncode() {
    let result = SearchResult(
        score: .nan,
        entry: DocumentationEntry(id: "/doc/X", framework: nil, kind: nil, title: nil, content: nil)
    )
    #expect(throws: EncodingError.self) { try JSONEncoder().encode(result) }
}

@available(macOS 26, *)
private func assertInfinityScoreThrowsOnEncode() {
    let result = SearchResult(
        score: .infinity,
        entry: DocumentationEntry(id: "/doc/X", framework: nil, kind: nil, title: nil, content: nil)
    )
    #expect(throws: EncodingError.self) { try JSONEncoder().encode(result) }
}

private func assertRoundTrip<T: Codable & Equatable>(_ value: T) throws {
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(T.self, from: data)
    #expect(decoded == value)
}
