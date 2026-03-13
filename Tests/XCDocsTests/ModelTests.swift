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
    func fetchResultHandlesEmptyAndSpecialCharacterFields() throws {
        guard #available(macOS 26, *) else { return }
        try fetchResultWithEmptyAndSpecialFields()
    }
}

@available(macOS 26, *)
private func publicModelsRoundTripThroughCodableOnSupportedOS() throws {
    try assertRoundTrip(DocumentationKind.article)
    try assertRoundTrip(
        SearchResult(
            identifier: "/documentation/Testing",
            score: 0.75,
            framework: "Swift Testing",
            kind: .article,
            title: "Swift Testing",
            content: "Create and run tests."
        )
    )
    try assertRoundTrip(
        FetchResult(
            identifier: "/documentation/Testing",
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
    try assertRoundTrip(SearchResult(identifier: "", score: 0.0, framework: nil, kind: nil, title: nil, content: nil))
    try assertRoundTrip(
        SearchResult(
            identifier: "/docs/special/<chars>&\"quotes\"",
            score: -1.0,
            framework: "",
            kind: .symbol,
            title: "Title with emoji \u{1F600} and newline\n",
            content: "Content with tabs\tand unicode \u{00E9}\u{00F1}"
        )
    )
}

@available(macOS 26, *)
private func fetchResultWithEmptyAndSpecialFields() throws {
    try assertRoundTrip(FetchResult(identifier: "", framework: nil, kind: nil, title: nil, content: nil))
    try assertRoundTrip(
        FetchResult(
            identifier: "/docs/special/<chars>&\"quotes\"",
            framework: "",
            kind: .topic,
            title: "Title with emoji \u{1F600} and newline\n",
            content: "Content with tabs\tand unicode \u{00E9}\u{00F1}"
        )
    )
}

private func assertRoundTrip<T: Codable & Equatable>(_ value: T) throws {
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(T.self, from: data)
    #expect(decoded == value)
}
