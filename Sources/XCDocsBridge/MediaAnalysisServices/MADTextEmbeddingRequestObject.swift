import Foundation

package struct MADTextEmbeddingRequestObject: PrivateObject {
    enum Key: String { case embeddingResults }

    let base: AnyObject

    package init() throws {
        try FrameworkLoader.loadMediaAnalysisServices()
        let cls = try Self.requiredNSObjectClass(named: "MADTextEmbeddingRequest")
        self.base = cls.init()
    }

    package var embeddingResults: [MADTextEmbeddingResultObject] {
        array(forKey: .embeddingResults).map(MADTextEmbeddingResultObject.init(base:))
    }

    package func float32EmbeddingData() throws -> Data {
        guard let result = embeddingResults.first else {
            throw BridgeError(.operationFailed, "MediaAnalysisServices completed without returning embedding data.")
        }

        let embeddingData = result.embeddingData
        guard !embeddingData.isEmpty else {
            throw BridgeError(.operationFailed, "MediaAnalysisServices completed without returning embedding data.")
        }

        let elementCount =
            result.elementCount > 0 ? result.elementCount : embeddingData.count / MemoryLayout<UInt16>.size
        let resolvedCount = embeddingData.count / MemoryLayout<UInt16>.size
        guard resolvedCount == elementCount else {
            throw BridgeError(
                .invalidEmbedding,
                "Embedding element count mismatch: expected \(elementCount), got \(resolvedCount)"
            )
        }

        var float32Data = Data(capacity: elementCount * MemoryLayout<Float>.size)
        embeddingData.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) in
            let halfValues = rawBuffer.bindMemory(to: UInt16.self)
            for bits in halfValues {
                var floatValue = Float(Float16(bitPattern: bits))
                withUnsafeBytes(of: &floatValue) { floatBytes in float32Data.append(contentsOf: floatBytes) }
            }
        }

        return float32Data
    }
}
