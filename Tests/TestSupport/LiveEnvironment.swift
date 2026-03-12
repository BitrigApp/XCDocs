import ExceptionCatcher
import Foundation
import XCDocsBridge
import XCDocsSupport

package enum LiveEnvironment {
    package static let documentationIdentifier = "/documentation/Testing"
    package static let searchFramework = "Swift Testing"
    package static let searchQuery = "swift testing"

    private static let mediaAnalysisServicesPath = "/System/Library/PrivateFrameworks/MediaAnalysisServices.framework"
    private static let vectorSearchPath = "/System/Library/PrivateFrameworks/VectorSearch.framework"
    private static let documentationAssetRootPath =
        "/System/Library/AssetsV2/com_apple_MobileAsset_AppleDeveloperDocumentation"

    package static var isAvailable: Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: mediaAnalysisServicesPath)
            && fileManager.fileExists(atPath: vectorSearchPath)
            && fileManager.fileExists(atPath: documentationAssetRootPath)
            && ((try? DocumentationAssetLocator().locateDatabaseDirectoryURL()) != nil)
    }

    package static func databaseDirectoryURL() throws -> URL {
        try DocumentationAssetLocator().locateDatabaseDirectoryURL()
    }

    package static func embeddingVector(for text: String) async throws -> Data {
        let service = try MADServiceObject()
        let request = try MADTextEmbeddingRequestObject()
        let textInput = try MADTextInputObject(text: text)

        try await withCheckedThrowingContinuation { continuation in
            let completionHandler: @convention(block) () -> Void = { continuation.resume() }
            let completionHandlerObject = completionHandler as AnyObject

            do {
                try runCatchingExceptions {
                    _ = try service.performRequests(
                        requests: [request],
                        textInputs: [textInput],
                        completionHandler: completionHandlerObject
                    )
                }
            } catch { continuation.resume(throwing: error) }
        }

        guard let result = request.embeddingResults.first, !result.embeddingData.isEmpty else {
            throw BridgeError(.operationFailed, "MediaAnalysisServices completed without returning embedding data.")
        }

        let elementCount =
            result.elementCount > 0 ? result.elementCount : result.embeddingData.count / MemoryLayout<UInt16>.size
        return try makeFloat32Data(from: result.embeddingData, expectedCount: elementCount)
    }

    private static func makeFloat32Data(from float16Data: Data, expectedCount: Int) throws -> Data {
        let resolvedCount = float16Data.count / MemoryLayout<UInt16>.size
        guard resolvedCount == expectedCount else {
            throw BridgeError(
                .invalidEmbedding,
                "Embedding element count mismatch: expected \(expectedCount), got \(resolvedCount)"
            )
        }

        var result = Data(capacity: expectedCount * MemoryLayout<Float>.size)
        float16Data.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) in
            let halfValues = rawBuffer.bindMemory(to: UInt16.self)
            for bits in halfValues {
                var floatValue = Float(Float16(bitPattern: bits))
                withUnsafeBytes(of: &floatValue) { floatBytes in result.append(contentsOf: floatBytes) }
            }
        }
        return result
    }
}
