import Foundation
import Testing

@testable import XCDocsBridge

@Suite("MADTextEmbeddingRequestObject")
struct MADTextEmbeddingRequestObjectTests {
    @Test
    func derivesElementCountFromAlignedFallbackPayload() async throws {
        let request = await MADTextEmbeddingRequestObject(
            base: EmbeddingRequestFixture(results: [
                EmbeddingResultFixture(
                    elementCount: 0,
                    embeddingData: embeddingData(bits: [Float16(1.5).bitPattern, Float16(-2).bitPattern])
                )
            ])
        )

        let float32Data = try await request.float32EmbeddingData()

        #expect(floatValues(from: float32Data) == [1.5, -2.0])
    }

    @Test
    func throwsForFallbackPayloadWithPartialFloat16Element() async {
        let request = await MADTextEmbeddingRequestObject(
            base: EmbeddingRequestFixture(results: [
                EmbeddingResultFixture(elementCount: 0, embeddingData: Data([0x00, 0x3C, 0x00]))
            ])
        )

        do {
            _ = try await request.float32EmbeddingData()
            Issue.record("Expected invalidEmbedding error for malformed fallback payload")
        } catch let error as BridgeError {
            #expect(error.code == .invalidEmbedding)
            #expect(error.message == "Embedding byte count mismatch: expected a multiple of 2, got 3")
        } catch { Issue.record("Unexpected error: \(error)") }
    }

    @Test
    func throwsForReportedElementCountMismatch() async {
        let request = await MADTextEmbeddingRequestObject(
            base: EmbeddingRequestFixture(results: [
                EmbeddingResultFixture(
                    elementCount: 3,
                    embeddingData: embeddingData(bits: [Float16(1).bitPattern, Float16(2).bitPattern])
                )
            ])
        )

        do {
            _ = try await request.float32EmbeddingData()
            Issue.record("Expected invalidEmbedding error for mismatched element count")
        } catch let error as BridgeError {
            #expect(error.code == .invalidEmbedding)
            #expect(error.message == "Embedding element count mismatch: expected 3, got 2")
        } catch { Issue.record("Unexpected error: \(error)") }
    }
}

@objcMembers
private final class EmbeddingRequestFixture: NSObject {
    dynamic var embeddingResults: [AnyObject]

    init(results: [EmbeddingResultFixture]) { self.embeddingResults = results }
}

@objcMembers
private final class EmbeddingResultFixture: NSObject {
    dynamic var elementCount: NSNumber
    dynamic var embeddingData: NSData

    init(elementCount: Int, embeddingData: Data) {
        self.elementCount = NSNumber(value: elementCount)
        self.embeddingData = embeddingData as NSData
    }
}

private func embeddingData(bits: [UInt16]) -> Data { bits.withUnsafeBytes { rawBuffer in Data(rawBuffer) } }

private func floatValues(from data: Data) -> [Float] {
    data.withUnsafeBytes { rawBuffer in Array(rawBuffer.bindMemory(to: Float.self)) }
}
