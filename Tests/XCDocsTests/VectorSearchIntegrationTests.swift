import TestSupport
import Testing

@testable import XCDocsBridge

@Suite("VectorSearch Integration", .enabled(if: LiveEnvironment.isAvailable), .serialized)
struct VectorSearchIntegrationTests {
    @Test
    func initializesConfigAndClientAgainstTheLiveDatabase() throws {
        let databaseDirectoryURL = try LiveEnvironment.databaseDirectoryURL()
        let config = try VSKConfigObject(baseDirectoryURL: databaseDirectoryURL, numberOfProbes: 8, readOnly: true)

        _ = try VSKClientObject(config: config)
    }

    @Test
    func looksUpAssetsByIdentifier() throws {
        let databaseDirectoryURL = try LiveEnvironment.databaseDirectoryURL()
        let config = try VSKConfigObject(baseDirectoryURL: databaseDirectoryURL, numberOfProbes: 8, readOnly: true)
        let client = try VSKClientObject(config: config)
        let attributes = try [VSKAttributeObject.stringNamed("framework"), VSKAttributeObject.stringNamed("title")]

        let assets = try client.stringIdentifiedAssets(
            identifiers: [LiveEnvironment.documentationIdentifier],
            attributeFilters: [],
            includeVectors: false,
            selectAttributes: attributes
        )

        let asset = try #require(assets.first)
        #expect(asset.stringIdentifier == LiveEnvironment.documentationIdentifier)
        #expect(asset.attributes["framework"] == LiveEnvironment.searchFramework)
        #expect(!(asset.attributes["title"] ?? "").isEmpty)
    }
}
