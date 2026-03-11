import Foundation
import TestSupport
import Testing

@testable import XCDocsBridge
@testable import XCDocsSupport

@Suite("Documentation Asset Locator")
struct DocumentationAssetLocatorTests {
  @Test
  func throwsWhenTheAssetRootIsMissing() throws {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)

    let error = try #require(
      captureBridgeError {
        try DocumentationAssetLocator(assetRootURL: rootURL).locateDatabaseDirectoryURL()
      })

    #expect(error.code == .assetNotFound)
    #expect(error.message.contains(rootURL.path))
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

@Suite(
  "Documentation Asset Locator Live Smoke", .enabled(if: LiveEnvironment.isAvailable), .serialized)
struct DocumentationAssetLocatorLiveSmokeTests {
  @Test
  func resolvesALiveDatabaseDirectoryContainingIndexSQL() throws {
    let databaseDirectoryURL = try DocumentationAssetLocator().locateDatabaseDirectoryURL()
    let indexURL = databaseDirectoryURL.appendingPathComponent("index.sql")

    #expect(FileManager.default.fileExists(atPath: databaseDirectoryURL.path))
    #expect(FileManager.default.fileExists(atPath: indexURL.path))
  }
}

private func captureBridgeError<T>(_ work: () throws -> T) -> BridgeError? {
  do {
    _ = try work()
    Issue.record("Expected BridgeError to be thrown.")
    return nil
  } catch let error as BridgeError {
    return error
  } catch {
    Issue.record("Unexpected error: \(String(describing: error))")
    return nil
  }
}

private func makeTemporaryDirectory() throws -> URL {
  let directoryURL = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString, isDirectory: true)
  try FileManager.default.createDirectory(
    at: directoryURL,
    withIntermediateDirectories: true
  )
  return directoryURL
}

private func createAsset(
  at assetURL: URL,
  includesIndex: Bool,
  modificationDate: Date
) throws -> URL {
  let fileManager = FileManager.default
  let databaseDirectoryURL =
    assetURL
    .appendingPathComponent("AssetData", isDirectory: true)
    .appendingPathComponent("documentation-db", isDirectory: true)

  try fileManager.createDirectory(
    at: databaseDirectoryURL,
    withIntermediateDirectories: true
  )
  if includesIndex {
    try Data().write(to: databaseDirectoryURL.appendingPathComponent("index.sql"))
  }
  try fileManager.setAttributes(
    [.modificationDate: modificationDate],
    ofItemAtPath: assetURL.path
  )
  return databaseDirectoryURL
}

private func canonicalFileURL(_ url: URL) -> URL {
  url.standardizedFileURL.resolvingSymlinksInPath()
}
