import ArgumentParser
import Foundation
import XCDocs

func printJSON<T: Encodable>(_ value: T) throws {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  let data = try encoder.encode(value)
  guard let string = String(data: data, encoding: .utf8) else {
    throw ValidationError("Failed to render JSON output.")
  }
  print(string)
}

func printCompactJSON<T: Encodable>(_ value: T) throws {
  let encoder = JSONEncoder()
  let data = try encoder.encode(value)
  guard let string = String(data: data, encoding: .utf8) else {
    throw ValidationError("Failed to render JSON output.")
  }
  print(string)
}

func printSearchResponse(_ response: SearchResponse) {
  for (index, result) in response.results.enumerated() {
    let renderedScore =
      result.score.isFinite
      ? String(format: "%.4f", result.score)
      : "nan"
    print("\(index + 1). [\(renderedScore)] \(result.identifier)")

    let metadata = [result.framework, result.kind, result.title]
      .compactMap { $0 }
      .joined(separator: " | ")
    if !metadata.isEmpty {
      print("   \(metadata)")
    }

    if let content = result.content, !content.isEmpty {
      let singleLineContent =
        content
        .replacingOccurrences(of: "\n", with: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      print("   \(singleLineContent)")
    }
  }
}
