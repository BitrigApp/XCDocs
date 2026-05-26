import Foundation

package struct ProcessResult: Sendable {
    package let terminationStatus: Int32
    package let stdout: String
    package let stderr: String

    package var exitStatus: Int32 {
        terminationStatus
    }

    package var combinedOutput: String { stdout + stderr }
}

package enum ProcessRunner {
    package static func runXCDocs(_ arguments: [String]) async throws -> ProcessResult {
        let executableURL = try xcdocsExecutableURL()
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.currentDirectoryURL = packageRootURL

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        return ProcessResult(
            terminationStatus: process.terminationStatus,
            stdout: String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
            stderr: String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        )
    }

    private static var packageRootURL: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static func xcdocsExecutableURL() throws -> URL {
        let fileManager = FileManager.default
        let buildURL = packageRootURL.appendingPathComponent(".build", isDirectory: true)

        let directCandidates = [
            buildURL.appendingPathComponent("debug/xcdocs"),
            buildURL.appendingPathComponent("arm64-apple-macosx/debug/xcdocs"),
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
            if fileManager.isExecutableFile(atPath: candidate.path) { return candidate }
        }

        throw NSError(
            domain: "TestSupport.ProcessRunner",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Unable to locate built xcdocs executable."]
        )
    }
}
