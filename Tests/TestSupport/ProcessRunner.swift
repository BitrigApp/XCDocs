import Foundation
import Subprocess

#if canImport(System)
  import System
#else
  import SystemPackage
#endif

package struct ProcessResult {
  package let terminationStatusDescription: String
  package let stdout: String
  package let stderr: String

  package var exitStatus: Int32 {
    guard terminationStatusDescription.hasPrefix("exited("),
      terminationStatusDescription.hasSuffix(")")
    else {
      return -1
    }

    let startIndex = terminationStatusDescription.index(
      terminationStatusDescription.startIndex,
      offsetBy: "exited(".count
    )
    let endIndex = terminationStatusDescription.index(before: terminationStatusDescription.endIndex)
    return Int32(terminationStatusDescription[startIndex..<endIndex]) ?? -1
  }

  package var combinedOutput: String {
    stdout + stderr
  }
}

package enum ProcessRunner {
  package static func runXCDocs(_ arguments: [String]) async throws -> ProcessResult {
    let executableURL = try xcdocsExecutableURL()
    let result = try await run(
      .path(FilePath(executableURL.path)),
      arguments: Arguments(arguments),
      workingDirectory: FilePath(packageRootURL.path),
      output: .string(limit: 1 << 20),
      error: .string(limit: 1 << 20)
    )

    return ProcessResult(
      terminationStatusDescription: String(describing: result.terminationStatus),
      stdout: result.standardOutput ?? "",
      stderr: result.standardError ?? ""
    )
  }

  private static var packageRootURL: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
  }

  private static func xcdocsExecutableURL() throws -> URL {
    let fileManager = FileManager.default
    let buildURL = packageRootURL.appendingPathComponent(".build", isDirectory: true)

    let directCandidates = [
      buildURL.appendingPathComponent("debug/xcdocs"),
      buildURL.appendingPathComponent("arm64-apple-macosx/debug/xcdocs"),
      buildURL.appendingPathComponent("x86_64-apple-macosx/debug/xcdocs"),
    ]

    for candidate in directCandidates where fileManager.isExecutableFile(atPath: candidate.path) {
      return candidate
    }

    let directories = try fileManager.contentsOfDirectory(
      at: buildURL,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    )

    for directory in directories {
      let isDirectory = try directory.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true
      guard isDirectory else { continue }

      let candidate = directory.appendingPathComponent("debug/xcdocs")
      if fileManager.isExecutableFile(atPath: candidate.path) {
        return candidate
      }
    }

    throw NSError(
      domain: "TestSupport.ProcessRunner",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Unable to locate built xcdocs executable."]
    )
  }
}
