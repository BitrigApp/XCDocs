import ArgumentParser
import XCDocs

struct VersionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "version", abstract: "Print the xcdocs version.")

    mutating func run() async throws { print(Version.string) }
}
