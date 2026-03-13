import ArgumentParser
import Foundation
import XCDocs

@available(macOS 26, *)
extension DocumentationKind: ExpressibleByArgument {}

@available(macOS 26, *)
struct SearchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "search", abstract: "Search the documentation asset.")

    @Argument(help: "The search query.")
    var queryParts: [String] = []

    @Option(name: .customLong("framework"), help: "Restrict results to a framework. Repeat to add more.")
    var frameworks: [String] = []

    @Option(
        name: .customLong("kind"),
        help: "Restrict results to a documentation kind like article, symbol, or topic. Repeat to add more."
    )
    var kinds: [DocumentationKind] = []

    @Option(help: "Maximum number of results to return.")
    var limit = 10

    @Flag(help: "Omit document contents from each result.")
    var omitContent = false

    @Flag(help: "Print the response as JSON.")
    var json = false

    mutating func validate() throws {
        guard !queryParts.isEmpty else { throw ValidationError("Search query is required.") }
    }

    mutating func run() async throws {
        let client = Client()
        let results = try await client.search(
            queryParts.joined(separator: " "),
            frameworks: frameworks,
            kinds: kinds,
            limit: limit,
            omitContent: omitContent
        )

        if json {
            try printDocumentationSearchJSON(results)
            return
        }

        printSearchResults(results)
    }
}

@available(macOS 26, *)
struct DocumentationSearchDocument: Encodable {
    let contents: String?
    let score: Double
    let title: String?
    let uri: String

    init(searchResult: SearchResult) {
        self.contents = searchResult.entry.content
        self.score = searchResult.score
        self.title = searchResult.entry.title
        self.uri = searchResult.entry.id
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contents, forKey: .contents)
        try container.encode(score, forKey: .score)
        try container.encode(title, forKey: .title)
        try container.encode(uri, forKey: .uri)
    }

    private enum CodingKeys: String, CodingKey { case contents, score, title, uri }
}

@available(macOS 26, *)
struct DocumentationSearchResponse: Encodable {
    let documents: [DocumentationSearchDocument]

    init(searchResults: [SearchResult]) { self.documents = searchResults.map(DocumentationSearchDocument.init) }
}

@available(macOS 26, *)
private func printDocumentationSearchJSON(_ results: [SearchResult]) throws {
    try printJSON(DocumentationSearchResponse(searchResults: results), prettyPrinted: false)
}
