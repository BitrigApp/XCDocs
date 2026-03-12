import ArgumentParser
import XCDocs

@main
struct CLIEntryPoint {
    static func main() async throws {
        guard #available(macOS 26, *) else {
            throw ValidationError("XCDocs requires macOS 26 or newer.")
        }
        try await CLI.main()
    }
}

@available(macOS 26, *)
struct CLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcdocs",
        abstract: "Search Apple developer documentation.",
        version: Version.string,
        subcommands: [SearchCommand.self, FetchCommand.self, VersionCommand.self],
        defaultSubcommand: SearchCommand.self
    )
}
