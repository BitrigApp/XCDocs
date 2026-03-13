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
        let service = try await MADServiceObject()
        let request = try await MADTextEmbeddingRequestObject()
        let textInput = try await MADTextInputObject(text: text)

        _ = try await service.performRequests(requests: [request], textInputs: [textInput])

        return try await request.float32EmbeddingData()
    }
}
