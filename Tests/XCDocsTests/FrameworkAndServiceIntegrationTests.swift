import TestSupport
import Testing

@testable import XCDocsBridge

@Suite("Framework and Service Integration", .enabled(if: LiveEnvironment.isAvailable), .serialized)
struct FrameworkAndServiceIntegrationTests {
    @Test
    func loadsPrivateFrameworksIdempotently() async throws {
        let firstMediaAnalysisBundle = try await FrameworkLoader.loadMediaAnalysisServices()
        let secondMediaAnalysisBundle = try await FrameworkLoader.loadMediaAnalysisServices()
        let firstVectorSearchBundle = try await FrameworkLoader.loadVectorSearch()
        let secondVectorSearchBundle = try await FrameworkLoader.loadVectorSearch()

        #expect(firstMediaAnalysisBundle.bundleURL == secondMediaAnalysisBundle.bundleURL)
        #expect(firstVectorSearchBundle.bundleURL == secondVectorSearchBundle.bundleURL)
    }

    @Test
    func mediaAnalysisServicesProducesAnEmbeddingVector() async throws {
        let service = try await MADServiceObject()
        let request = try await MADTextEmbeddingRequestObject()
        let textInput = try await MADTextInputObject(text: LiveEnvironment.searchQuery)
        let vector = try await LiveEnvironment.embeddingVector(for: LiveEnvironment.searchQuery)
        let embeddingResults = await request.embeddingResults

        #expect(embeddingResults.isEmpty)
        #expect(!vector.isEmpty)
        #expect(vector.count.isMultiple(of: MemoryLayout<Float>.size))
        _ = service
        _ = textInput
    }
}
