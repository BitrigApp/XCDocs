import TestSupport
import Testing

@testable import XCDocsBridge

@Suite("Framework and Service Integration", .enabled(if: LiveEnvironment.isAvailable), .serialized) struct FrameworkAndServiceIntegrationTests {
    @Test func loadsPrivateFrameworksIdempotently() throws {
        let firstMediaAnalysisBundle = try FrameworkLoader.loadMediaAnalysisServices()
        let secondMediaAnalysisBundle = try FrameworkLoader.loadMediaAnalysisServices()
        let firstVectorSearchBundle = try FrameworkLoader.loadVectorSearch()
        let secondVectorSearchBundle = try FrameworkLoader.loadVectorSearch()

        #expect(firstMediaAnalysisBundle.bundleURL == secondMediaAnalysisBundle.bundleURL)
        #expect(firstVectorSearchBundle.bundleURL == secondVectorSearchBundle.bundleURL)
    }

    @Test func mediaAnalysisServicesProducesAnEmbeddingVector() async throws {
        let service = try MADServiceObject()
        let request = try MADTextEmbeddingRequestObject()
        let textInput = try MADTextInputObject(text: LiveEnvironment.searchQuery)
        let vector = try await LiveEnvironment.embeddingVector(for: LiveEnvironment.searchQuery)

        #expect(request.embeddingResults.isEmpty)
        #expect(!vector.isEmpty)
        #expect(vector.count.isMultiple(of: MemoryLayout<Float>.size))
        _ = service
        _ = textInput
    }
}
