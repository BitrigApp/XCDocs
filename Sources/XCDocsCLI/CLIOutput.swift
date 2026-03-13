import Darwin
import ArgumentParser
import Foundation
import XCDocs

func printJSON<T: Encodable>(_ value: T, prettyPrinted: Bool = true) throws {
    let encoder = JSONEncoder()
    if prettyPrinted { encoder.outputFormatting = [.prettyPrinted, .sortedKeys] }
    let data = try encoder.encode(value)
    guard let string = String(data: data, encoding: .utf8) else {
        throw ValidationError("Failed to render JSON output.")
    }
    print(string)
}

@available(macOS 26, *)
func printSearchResults(_ results: [SearchResult]) {
    for (index, result) in results.enumerated() {
        print(renderTextEntry(result.entry, score: result.score, index: index + 1), terminator: "")
    }
}

@available(macOS 26, *)
func renderTextEntry(_ entry: DocumentationEntry, score: Double? = nil, index: Int? = nil) -> String {
    let supportsStyling = terminalSupportsANSIStyling()
    let prefix = index.map { "\($0). " } ?? ""
    let indentation = String(repeating: " ", count: prefix.count)
    let headline = prefix + (entry.title ?? entry.id)

    var lines = [renderBold(headline, enabled: supportsStyling)]

    if let kind = entry.kind?.rawValue {
        lines.append("\(indentation)\(renderBold("Kind:", enabled: supportsStyling)) \(kind)")
    }

    if let score {
        let renderedScore = score.isFinite ? String(format: "%.4f", score) : "nan"
        lines.append("\(indentation)\(renderBold("Relevance:", enabled: supportsStyling)) \(renderedScore)")
    }

    lines.append("\(indentation)\(renderBold("ID:", enabled: supportsStyling)) \(entry.id)")
    lines.append("")

    if let content = entry.content?.trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty {
        lines.append(contentsOf: renderIndentedContentLines(content, indentation: indentation))
    }

    lines.append("")
    lines.append("")
    return lines.joined(separator: "\n")
}

private func renderIndentedContentLines(_ content: String, indentation: String) -> [String] {
    content.split(separator: "\n", omittingEmptySubsequences: false).map { "\(indentation)\($0)" }
}

private func renderBold(_ text: String, enabled: Bool) -> String {
    guard enabled else { return text }
    return "\u{001B}[1m\(text)\u{001B}[22m"
}

private func terminalSupportsANSIStyling() -> Bool {
    if environmentValue(named: "CLICOLOR_FORCE") == "1" { return true }
    if environmentValue(named: "NO_COLOR") != nil { return false }
    guard isatty(STDOUT_FILENO) != 0 else { return false }
    return environmentValue(named: "TERM") != "dumb"
}

private func environmentValue(named name: String) -> String? {
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
}
