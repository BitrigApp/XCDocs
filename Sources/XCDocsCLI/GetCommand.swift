import ArgumentParser
import Foundation
import XCDocs

@available(macOS 26, *)
struct GetCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get a documentation entry by identifier."
    )

    @Argument(help: "The documentation identifier, for example /documentation/SwiftUI/List.")
    var identifier: String

    @Flag(help: "Print the response as JSON.")
    var json = false

    mutating func run() async throws {
        let client = Client()
        let result = try await client.entry(for: identifier)

        if json {
            try printJSON(result)
            return
        }

        print(renderTextEntry(result), terminator: "")
    }
}
