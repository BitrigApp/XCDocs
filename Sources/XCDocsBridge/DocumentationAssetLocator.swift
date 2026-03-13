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
        let contents = try assetRootContents()

        let candidates = try contents.filter { $0.pathExtension == "asset" }.filter { try hasReadableIndex(at: $0) }
            .sorted { lhs, rhs in modificationDate(for: lhs) > modificationDate(for: rhs) }

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
        let indexURL = indexURL(forAssetURL: assetURL)
        do { try openAndCloseFile(at: indexURL) } catch {
            if isMissingFileError(error) {
                throw BridgeError(
                    .assetNotFound,
                    "Documentation index is missing at \(indexURL.path)",
                    underlyingError: error
                )
            }

            throw error
        }

        return databaseDirectoryURL
    }

    private func assetRootContents() throws -> [URL] {
        do {
            return try fileManager.contentsOfDirectory(
                at: assetRootURL,
                includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            if isMissingFileError(error) {
                throw BridgeError(
                    .assetNotFound,
                    "Documentation asset root is missing at \(assetRootURL.path)",
                    underlyingError: error
                )
            }

            throw error
        }
    }

    private func hasReadableIndex(at assetURL: URL) throws -> Bool {
        do {
            try openAndCloseFile(at: indexURL(forAssetURL: assetURL))
            return true
        } catch {
            if isMissingFileError(error) { return false }

            throw error
        }
    }

    private func indexURL(forAssetURL assetURL: URL) -> URL {
        assetURL.appendingPathComponent("AssetData", isDirectory: true).appendingPathComponent(
            "documentation-db",
            isDirectory: true
        ).appendingPathComponent("index.sql")
    }

    private func openAndCloseFile(at url: URL) throws {
        let handle = try FileHandle(forReadingFrom: url)
        handle.closeFile()
    }

    private func isMissingFileError(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSCocoaErrorDomain else { return false }
        return nsError.code == NSFileNoSuchFileError || nsError.code == NSFileReadNoSuchFileError
    }

    private func modificationDate(for url: URL) -> Date {
        let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return resourceValues?.contentModificationDate ?? .distantPast
    }
}
