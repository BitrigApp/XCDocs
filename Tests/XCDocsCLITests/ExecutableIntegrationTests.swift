import Foundation
import TestSupport
import Testing

@Suite("xcdocs Executable") struct ExecutableIntegrationTests {
    @Test func helpRendersExpectedTopLevelOutput() async throws {
        let result = try await ProcessRunner.runXCDocs(["--help"])

        #expect(result.exitStatus == 0)
        #expect(result.stdout.contains("Search Apple developer documentation."))
        #expect(result.stdout.contains("search (default)"))
        #expect(result.stdout.contains("fetch"))
        #expect(result.stdout.contains("version"))
    }

    @Test func missingQueryFailsValidation() async throws {
        let result = try await ProcessRunner.runXCDocs(["search"])

        #expect(result.exitStatus == 64)
        #expect(result.combinedOutput.contains("Search query is required."))
    }
}

@Suite("xcdocs Executable Live Integration", .enabled(if: LiveEnvironment.isAvailable), .serialized)
struct ExecutableLiveIntegrationTests {
    @Test func searchJSONMatchesTheExpectedMCPShape() async throws {
        let result = try await ProcessRunner.runXCDocs([
            "search", LiveEnvironment.searchQuery, "--framework", LiveEnvironment.searchFramework, "--limit", "3",
            "--json",
        ])

        let json = try dictionaryJSON(from: result.stdout)
        let documents = try #require(json["documents"] as? [[String: Any]])
        let firstDocument = try #require(documents.first)

        #expect(result.exitStatus == 0)
        #expect(!documents.isEmpty)
        #expect(firstDocument["uri"] as? String != nil)
        #expect(firstDocument["title"] as? String != nil)
        #expect(firstDocument["contents"] as? String != nil)
        #expect(firstDocument["score"] as? NSNumber != nil)
    }

    @Test func searchAcceptsKindFilters() async throws {
        let result = try await ProcessRunner.runXCDocs([
            "search", LiveEnvironment.searchQuery, "--framework", LiveEnvironment.searchFramework, "--kind", "article",
            "--limit", "3", "--omit-content",
        ])

        #expect(result.exitStatus == 0)
        #expect(result.stdout.contains("article"))
    }

    @Test func fetchJSONContainsTheExpectedResultShape() async throws {
        let result = try await ProcessRunner.runXCDocs(["fetch", LiveEnvironment.documentationIdentifier, "--json"])

        let json = try dictionaryJSON(from: result.stdout)

        #expect(result.exitStatus == 0)
        #expect(json["identifier"] as? String == LiveEnvironment.documentationIdentifier)
        #expect(json["framework"] as? String == LiveEnvironment.searchFramework)
        #expect(json["title"] as? String != nil)
    }

    @Test func missingIdentifiersReturnTheRepoDefinedErrorMessage() async throws {
        let result = try await ProcessRunner.runXCDocs(["fetch", "/documentation/DefinitelyNotReal"])

        #expect(result.exitStatus == 1)
        #expect(
            result.combinedOutput.contains(
                "[assetNotFound] No documentation entry was found for /documentation/DefinitelyNotReal"
            )
        )
    }
}

private func dictionaryJSON(from string: String) throws -> [String: Any] {
    let data = Data(string.utf8)
    let object = try JSONSerialization.jsonObject(with: data)
    return try #require(object as? [String: Any])
}
