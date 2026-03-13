import Foundation

package struct MADTextEmbeddingRequestObject: PrivateObject {
    enum Key: String { case embeddingResults }

    let base: AnyObject

    package init(base: AnyObject) { self.base = base }

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

        let bytesPerElement = MemoryLayout<UInt16>.size
        guard embeddingData.count.isMultiple(of: bytesPerElement) else {
            throw BridgeError(
                .invalidEmbedding,
                "Embedding byte count mismatch: expected a multiple of \(bytesPerElement), got \(embeddingData.count)"
            )
        }

        let resolvedCount = embeddingData.count / bytesPerElement
        let elementCount: Int

        if result.elementCount > 0 {
            elementCount = result.elementCount
            guard resolvedCount == elementCount else {
                throw BridgeError(
                    .invalidEmbedding,
                    "Embedding element count mismatch: expected \(elementCount), got \(resolvedCount)"
                )
            }
        } else {
            elementCount = resolvedCount
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
