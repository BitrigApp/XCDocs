import ArgumentParser
import Foundation
import XCDocs

@available(macOS 26, *)
struct FetchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fetch",
        abstract: "Fetch a documentation entry by identifier."
    )

    @Argument(help: "The documentation identifier, for example /documentation/SwiftUI/List.") var identifier: String

    @Flag(help: "Print the response as JSON.") var json = false

    mutating func run() async throws {
        let client = Client()
        let result = try client.fetch(identifier)

        if json {
            try printJSON(result)
            return
        }

        printFetchResult(result)
    }
}

private func printFetchResult(_ result: FetchResult) {
    print(result.identifier)

    let metadata = [result.framework, result.kind?.rawValue, result.title].compactMap { $0 }.joined(separator: " | ")
    if !metadata.isEmpty { print(metadata) }

    if let content = result.content, !content.isEmpty {
        print("")
        print(content)
    }
}
