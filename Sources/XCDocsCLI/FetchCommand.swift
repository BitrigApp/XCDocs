import ArgumentParser
import Foundation
import XCDocs

struct FetchCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "fetch",
    abstract: "Fetch a documentation entry by identifier."
  )

  @Argument(help: "The documentation identifier, for example /documentation/SwiftUI/List.")
  var identifier: String

  @Flag(help: "Print the response as JSON.")
  var json = false

  mutating func run() async throws {
    let client = Client()
    let response = try client.fetch(FetchRequest(identifier: identifier))

    if json {
      try printJSON(response)
      return
    }

    printFetchResponse(response)
  }
}

private func printFetchResponse(_ response: FetchResponse) {
  print(response.result.identifier)

  let metadata = [response.result.framework, response.result.kind, response.result.title]
    .compactMap { $0 }
    .joined(separator: " | ")
  if !metadata.isEmpty {
    print(metadata)
  }

  if let content = response.result.content, !content.isEmpty {
    print("")
    print(content)
  }
}
