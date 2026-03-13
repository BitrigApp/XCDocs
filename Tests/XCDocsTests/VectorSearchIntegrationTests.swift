import TestSupport
import Testing

@testable import XCDocsBridge

@Suite("VectorSearch Integration", .enabled(if: LiveEnvironment.isAvailable), .serialized)
struct VectorSearchIntegrationTests {
    @Test
    func initializesConfigAndClientAgainstTheLiveDatabase() async throws {
        let databaseDirectoryURL = try LiveEnvironment.databaseDirectoryURL()
        let config = try await VSKConfigObject(
            baseDirectoryURL: databaseDirectoryURL,
            numberOfProbes: 8,
            readOnly: true
        )

        _ = try await VSKClientObject(config: config)
    }

    @Test
    func looksUpAssetsByIdentifier() async throws {
        let databaseDirectoryURL = try LiveEnvironment.databaseDirectoryURL()
        let config = try await VSKConfigObject(
            baseDirectoryURL: databaseDirectoryURL,
            numberOfProbes: 8,
            readOnly: true
        )
        let client = try await VSKClientObject(config: config)
        let frameworkAttribute = try await VSKAttributeObject.stringAttribute(named: "framework")
        let titleAttribute = try await VSKAttributeObject.stringAttribute(named: "title")
        let attributes = [frameworkAttribute, titleAttribute]

        let assets = try await client.assets(
            forIdentifiers: [LiveEnvironment.documentationIdentifier],
            attributeFilters: [],
            includeVectors: false,
            selectedAttributes: attributes
        )

        let asset = try #require(assets.first)
        let identifier = await asset.identifier
        let assetAttributes = await asset.attributes

        #expect(identifier == LiveEnvironment.documentationIdentifier)
        #expect(assetAttributes["framework"] == LiveEnvironment.searchFramework)
        #expect(!(assetAttributes["title"] ?? "").isEmpty)
    }
}
