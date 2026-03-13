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
        let renderedScore = result.score.isFinite ? String(format: "%.4f", result.score) : "nan"
        print("\(index + 1). [\(renderedScore)] \(result.entry.id)")

        let metadata = [result.entry.framework, result.entry.kind?.rawValue, result.entry.title].compactMap { $0 }
            .joined(separator: " | ")
        if !metadata.isEmpty { print("   \(metadata)") }

        if let content = result.entry.content, !content.isEmpty {
            let singleLineContent = content.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            print("   \(singleLineContent)")
        }
    }
}
