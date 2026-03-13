import Foundation

package struct DocumentationAssetLocator {
    private static let defaultAssetRootURL = URL(
        fileURLWithPath: "/System/Library/AssetsV2/com_apple_MobileAsset_AppleDeveloperDocumentation",
        isDirectory: true
    )

    private let assetRootURL: URL
    private let fileManager: FileManager

    package init(assetRootURL: URL = Self.defaultAssetRootURL, fileManager: FileManager = .default) {
        self.assetRootURL = assetRootURL
        self.fileManager = fileManager
    }

    package func locateDatabaseDirectoryURL() throws -> URL {
        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(
                at: assetRootURL,
                includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        } catch { throw BridgeError(.assetNotFound, "Documentation asset root is missing at \(assetRootURL.path)") }

        let candidates = contents.filter { $0.pathExtension == "asset" }.filter { candidate in
            let indexURL = candidate.appendingPathComponent("AssetData", isDirectory: true).appendingPathComponent(
                "documentation-db",
                isDirectory: true
            ).appendingPathComponent("index.sql")
            return (try? FileHandle(forReadingFrom: indexURL)) != nil
        }.sorted { lhs, rhs in modificationDate(for: lhs) > modificationDate(for: rhs) }

        guard let assetURL = candidates.first else {
            throw BridgeError(
                .assetNotFound,
                "No AppleDeveloperDocumentation asset was found under \(assetRootURL.path)"
            )
        }

        return try databaseDirectoryURL(fromAssetURL: assetURL)
    }

    private func databaseDirectoryURL(fromAssetURL assetURL: URL) throws -> URL {
        let assetDataURL = assetURL.appendingPathComponent("AssetData", isDirectory: true)
        let databaseDirectoryURL = assetDataURL.appendingPathComponent("documentation-db", isDirectory: true)
        let indexURL = databaseDirectoryURL.appendingPathComponent("index.sql")
        do {
            let handle = try FileHandle(forReadingFrom: indexURL)
            handle.closeFile()
        } catch { throw BridgeError(.assetNotFound, "Documentation index is missing at \(indexURL.path)") }

        return databaseDirectoryURL
    }

    private func modificationDate(for url: URL) -> Date {
        let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return resourceValues?.contentModificationDate ?? .distantPast
    }
}
