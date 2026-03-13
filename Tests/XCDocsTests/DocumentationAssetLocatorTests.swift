import Foundation
import TestSupport
import Testing

@testable import XCDocsBridge
@testable import XCDocsSupport

@Suite("Documentation Asset Locator")
struct DocumentationAssetLocatorTests {
    @Test
    func throwsWhenTheAssetRootIsMissing() throws {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )

        let error = try #require(
            captureBridgeError { try DocumentationAssetLocator(assetRootURL: rootURL).locateDatabaseDirectoryURL() }
        )

        #expect(error.code == .assetNotFound)
        #expect(error.message.contains(rootURL.path))
        #expect((error.underlyingError as NSError?)?.domain == NSCocoaErrorDomain)
        #expect((error.underlyingError as NSError?)?.code == NSFileReadNoSuchFileError)
    }

    @Test
    func rethrowsNonMissingAssetRootLookupErrors() throws {
        let rootURL = URL(fileURLWithPath: "/tmp/asset-root", isDirectory: true)
        let underlyingError = NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileReadNoPermissionError,
            userInfo: [NSLocalizedDescriptionKey: "Permission denied"]
        )
        let locator = DocumentationAssetLocator(
            assetRootURL: rootURL,
            fileManager: StubFileManager(contentsOfDirectoryError: underlyingError)
        )

        do {
            _ = try locator.locateDatabaseDirectoryURL()
            Issue.record("Expected non-missing filesystem error to be rethrown.")
        } catch let error as BridgeError {
            Issue.record("Expected underlying filesystem error, got BridgeError: \(error)")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == underlyingError.domain)
            #expect(nsError.code == underlyingError.code)
            #expect(nsError.localizedDescription == underlyingError.localizedDescription)
        }
    }

    @Test
    func rethrowsNonMissingIndexReadErrorsDuringCandidateFiltering() throws {
        let rootURL = try makeTemporaryDirectory()
        let assetURL = rootURL.appendingPathComponent("blocked.asset", isDirectory: true)
        let databaseDirectoryURL = try createAsset(
            at: assetURL,
            includesIndex: true,
            modificationDate: .distantPast.addingTimeInterval(10)
        )
        let indexURL = databaseDirectoryURL.appendingPathComponent("index.sql")

        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: indexURL.path)
            try? FileManager.default.removeItem(at: rootURL)
        }

        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: indexURL.path)

        do {
            _ = try DocumentationAssetLocator(assetRootURL: rootURL).locateDatabaseDirectoryURL()
            Issue.record("Expected unreadable index error to be rethrown.")
        } catch let error as BridgeError {
            Issue.record("Expected underlying filesystem error, got BridgeError: \(error)")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == NSCocoaErrorDomain)
            #expect(nsError.code == NSFileReadNoPermissionError || nsError.code == NSFileWriteNoPermissionError)
        }
    }

    @Test
    func ignoresInvalidAssetsWhenSelectingTheDatabaseDirectory() throws {
        let rootURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let olderValidAssetURL = rootURL.appendingPathComponent("older.asset", isDirectory: true)
        let newerInvalidAssetURL = rootURL.appendingPathComponent("newer.asset", isDirectory: true)
        let olderValidDatabaseURL = try createAsset(
            at: olderValidAssetURL,
            includesIndex: true,
            modificationDate: .distantPast.addingTimeInterval(10)
        )
        _ = try createAsset(
            at: newerInvalidAssetURL,
            includesIndex: false,
            modificationDate: .distantPast.addingTimeInterval(20)
        )

        let locator = DocumentationAssetLocator(assetRootURL: rootURL)
        let databaseDirectoryURL = try locator.locateDatabaseDirectoryURL()

        #expect(canonicalFileURL(databaseDirectoryURL) == canonicalFileURL(olderValidDatabaseURL))
    }

    @Test
    func selectsSingleValidAsset() throws {
        let rootURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let assetURL = rootURL.appendingPathComponent("only.asset", isDirectory: true)
        let databaseURL = try createAsset(
            at: assetURL,
            includesIndex: true,
            modificationDate: .distantPast.addingTimeInterval(10)
        )

        let locator = DocumentationAssetLocator(assetRootURL: rootURL)
        let result = try locator.locateDatabaseDirectoryURL()

        #expect(canonicalFileURL(result) == canonicalFileURL(databaseURL))
    }

    @Test
    func selectsEitherAssetWhenModificationTimestampsAreIdentical() throws {
        let rootURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let timestamp = Date.distantPast.addingTimeInterval(100)
        let assetAURL = rootURL.appendingPathComponent("a.asset", isDirectory: true)
        let assetBURL = rootURL.appendingPathComponent("b.asset", isDirectory: true)
        let dbA = try createAsset(at: assetAURL, includesIndex: true, modificationDate: timestamp)
        let dbB = try createAsset(at: assetBURL, includesIndex: true, modificationDate: timestamp)

        let locator = DocumentationAssetLocator(assetRootURL: rootURL)
        let result = try locator.locateDatabaseDirectoryURL()
        let canonical = canonicalFileURL(result)

        #expect(canonical == canonicalFileURL(dbA) || canonical == canonicalFileURL(dbB))
    }

    @Test
    func throwsWhenAllCandidateAssetsAreInvalid() throws {
        let rootURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }

        _ = try createAsset(
            at: rootURL.appendingPathComponent("bad1.asset", isDirectory: true),
            includesIndex: false,
            modificationDate: .distantPast.addingTimeInterval(10)
        )
        _ = try createAsset(
            at: rootURL.appendingPathComponent("bad2.asset", isDirectory: true),
            includesIndex: false,
            modificationDate: .distantPast.addingTimeInterval(20)
        )

        let error = try #require(
            captureBridgeError { try DocumentationAssetLocator(assetRootURL: rootURL).locateDatabaseDirectoryURL() }
        )

        #expect(error.code == .assetNotFound)
    }

    @Test
    func propagatesErrorWhenModificationDateLookupFails() throws {
        let nonexistentURL = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString).asset")
        let locator = DocumentationAssetLocator()

        #expect(throws: (any Error).self) { try locator.modificationDate(for: nonexistentURL) }
    }

    @Test
    func selectsTheNewestValidAsset() throws {
        let rootURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let olderAssetURL = rootURL.appendingPathComponent("older.asset", isDirectory: true)
        let newerAssetURL = rootURL.appendingPathComponent("newer.asset", isDirectory: true)
        _ = try createAsset(
            at: olderAssetURL,
            includesIndex: true,
            modificationDate: .distantPast.addingTimeInterval(10)
        )
        let newerDatabaseURL = try createAsset(
            at: newerAssetURL,
            includesIndex: true,
            modificationDate: .distantPast.addingTimeInterval(20)
        )

        let locator = DocumentationAssetLocator(assetRootURL: rootURL)
        let databaseDirectoryURL = try locator.locateDatabaseDirectoryURL()

        #expect(canonicalFileURL(databaseDirectoryURL) == canonicalFileURL(newerDatabaseURL))
    }
}

@Suite("Documentation Asset Locator Live Smoke", .enabled(if: LiveEnvironment.isAvailable), .serialized)
struct DocumentationAssetLocatorLiveSmokeTests {
    @Test
    func resolvesALiveDatabaseDirectoryContainingIndexSQL() throws {
        let databaseDirectoryURL = try DocumentationAssetLocator().locateDatabaseDirectoryURL()
        let indexURL = databaseDirectoryURL.appendingPathComponent("index.sql")

        #expect(FileManager.default.fileExists(atPath: databaseDirectoryURL.path))
        #expect(FileManager.default.fileExists(atPath: indexURL.path))
    }
}

private func makeTemporaryDirectory() throws -> URL {
    let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(
        UUID().uuidString,
        isDirectory: true
    )
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    return directoryURL
}

private func createAsset(at assetURL: URL, includesIndex: Bool, modificationDate: Date) throws -> URL {
    let fileManager = FileManager.default
    let databaseDirectoryURL = assetURL.appendingPathComponent("AssetData", isDirectory: true).appendingPathComponent(
        "documentation-db",
        isDirectory: true
    )

    try fileManager.createDirectory(at: databaseDirectoryURL, withIntermediateDirectories: true)
    if includesIndex { try Data().write(to: databaseDirectoryURL.appendingPathComponent("index.sql")) }
    try fileManager.setAttributes([.modificationDate: modificationDate], ofItemAtPath: assetURL.path)
    return databaseDirectoryURL
}

private func canonicalFileURL(_ url: URL) -> URL { url.standardizedFileURL.resolvingSymlinksInPath() }

private final class StubFileManager: FileManager {
    private let contentsOfDirectoryError: Error

    init(contentsOfDirectoryError: Error) {
        self.contentsOfDirectoryError = contentsOfDirectoryError
        super.init()
    }

    override func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: DirectoryEnumerationOptions = []
    ) throws -> [URL] { throw contentsOfDirectoryError }
}
