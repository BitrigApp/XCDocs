import ArgumentParser
import XCDocs

@available(macOS 26, *)
struct VersionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "version", abstract: "Print the xcdocs version.")

    mutating func run() async throws { print(Version.current) }
}
