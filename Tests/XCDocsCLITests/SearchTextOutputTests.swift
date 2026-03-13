import Darwin
import Testing
import XCDocs

@testable import XCDocsCLI

@Suite("Search Text Output")
struct SearchTextOutputTests {
    @Test
    func searchResultUsesExpandedMetadataLayout() throws {
        guard #available(macOS 26, *) else { return }
        try assertSearchResultUsesExpandedMetadataLayout()
    }

    @Test
    func searchResultAlignsMetadataWithDoubleDigitIndex() throws {
        guard #available(macOS 26, *) else { return }
        try assertSearchResultAlignsMetadataWithDoubleDigitIndex()
    }

    @Test
    func getOutputUsesNoLeadingIndentation() throws {
        guard #available(macOS 26, *) else { return }
        try assertGetOutputUsesNoLeadingIndentation()
    }
}

@available(macOS 26, *)
private func assertSearchResultUsesExpandedMetadataLayout() throws {
    let result = makeSearchResult(
        score: 0.5405,
        id: "/documentation/Metal/MTLClearColor/init(red:green:blue:alpha:)",
        title: "init(red:green:blue:alpha:)"
    )

    let output = try withEnvironment(variable: "CLICOLOR_FORCE", value: "1") {
        renderTextEntry(result.entry, score: result.score, index: 1)
    }

    let expectedOutput = [
        bold("1. init(red:green:blue:alpha:)"), "   \(bold("Kind:")) symbol", "   \(bold("Relevance:")) 0.5405",
        "   \(bold("ID:")) /documentation/Metal/MTLClearColor/init(red:green:blue:alpha:)", "", "   [content]", "", "",
    ].joined(separator: "\n")

    #expect(output == expectedOutput)
}

@available(macOS 26, *)
private func assertSearchResultAlignsMetadataWithDoubleDigitIndex() throws {
    let result = makeSearchResult(score: 0.5120, id: "/documentation/Testing/result-12", title: "Result 12")

    let output = try withEnvironment(variable: "CLICOLOR_FORCE", value: "1") {
        renderTextEntry(result.entry, score: result.score, index: 12)
    }

    let expectedBlock = [
        bold("12. Result 12"), "    \(bold("Kind:")) symbol", "    \(bold("Relevance:")) 0.5120",
        "    \(bold("ID:")) /documentation/Testing/result-12", "", "    [content]", "", "",
    ].joined(separator: "\n")

    #expect(output.contains(expectedBlock))
}

@available(macOS 26, *)
private func assertGetOutputUsesNoLeadingIndentation() throws {
    let entry = DocumentationEntry(
        id: "/documentation/Metal/MTLClearColor/init(red:green:blue:alpha:)",
        framework: "Metal",
        kind: .symbol,
        title: "init(red:green:blue:alpha:)",
        content: "[content]"
    )

    let output = try withEnvironment(variable: "CLICOLOR_FORCE", value: "1") { renderTextEntry(entry) }

    let expectedOutput = [
        bold("init(red:green:blue:alpha:)"), "\(bold("Kind:")) symbol",
        "\(bold("ID:")) /documentation/Metal/MTLClearColor/init(red:green:blue:alpha:)", "", "[content]", "", "",
    ].joined(separator: "\n")

    #expect(output == expectedOutput)
}

@available(macOS 26, *)
private func makeSearchResult(score: Double, id: String, title: String) -> SearchResult {
    SearchResult(
        score: score,
        entry: DocumentationEntry(id: id, framework: "Metal", kind: .symbol, title: title, content: "[content]")
    )
}

private func bold(_ string: String) -> String { "\u{001B}[1m\(string)\u{001B}[22m" }

private func withEnvironment<T>(variable: String, value: String, _ work: () throws -> T) throws -> T {
    let previousValue = getenv(variable).map { String(cString: $0) }
    setenv(variable, value, 1)

    defer { if let previousValue { setenv(variable, previousValue, 1) } else { unsetenv(variable) } }

    return try work()
}
