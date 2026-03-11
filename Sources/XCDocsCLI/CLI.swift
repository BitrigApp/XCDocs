import ArgumentParser
import XCDocs

@main
struct CLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcdocs",
        abstract: "Search Apple developer documentation.",
        version: Version.string,
        subcommands: [
            SearchCommand.self,
            FetchCommand.self,
            VersionCommand.self,
        ],
        defaultSubcommand: SearchCommand.self
    )
}
