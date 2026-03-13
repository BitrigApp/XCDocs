import ExceptionCatcher
import Foundation
import XCDocsBridge
import XCDocsSupport

/// A high-level client for searching and fetching Apple's local developer documentation.
///
/// `Client` locates the on-disk documentation asset that ships with Xcode and macOS,
/// generates semantic query embeddings using Apple's private embedding service, and
/// resolves search results into stable Swift value types.
@available(macOS 26, *)
public struct Client {
    /// Creates a client for interacting with the local documentation asset.
    public init() {}

    /// Runs a semantic documentation search against Apple's local documentation database.
    ///
    /// The query text is embedded with Apple's local embedding service and then
    /// searched against the installed documentation vector index. The returned results may
    /// include optional metadata such as framework, kind, title, and content depending on
    /// what the underlying documentation asset contains and whether content retrieval was
    /// requested.
    ///
    /// - Parameters:
    ///   - query: The natural-language query text.
    ///   - frameworks: Optional framework filters to constrain the search.
    ///   - kinds: Optional kind filters to constrain the search.
    ///   - limit: The maximum number of ranked matches to return.
    ///   - omitContent: Whether to omit full document contents from each result.
    /// - Returns: The ranked documentation search results.
    /// - Throws: An error if the local documentation asset cannot be found, if embedding
    ///   generation fails, or if the vector search backend returns an error.
    public func search(
        _ query: String,
        frameworks: [String] = [],
        kinds: [DocumentationKind] = [],
        limit: Int = 10,
        omitContent: Bool = true
    ) async throws -> [SearchResult] {
        let databaseDirectoryURL = try DocumentationAssetLocator().locateDatabaseDirectoryURL()
        let vector = try await embeddingVector(for: query)

        let searchClient = try VectorSearchClient(databaseDirectoryURL: databaseDirectoryURL, readOnly: true)

        let hits = try searchClient.search(
            vector: vector,
            frameworks: frameworks,
            kinds: kinds.map(\.rawValue),
            limit: limit,
            omitContent: omitContent
        )

        return hits.map {
            SearchResult(
                identifier: $0.identifier,
                score: $0.score,
                framework: $0.framework,
                kind: $0.type.flatMap(DocumentationKind.init(rawValue:)),
                title: $0.title,
                content: $0.content
            )
        }
    }

    /// Fetches a single documentation entry by its stable documentation identifier.
    ///
    /// Use this when you already know the exact identifier for an entry, such as a path like
    /// `/documentation/SwiftUI/Color`. Unlike `search(_:frameworks:kinds:limit:omitContent:)`,
    /// this does not generate an embedding or run a semantic ranking step.
    ///
    /// - Parameter identifier: The identifier to resolve from the local documentation asset.
    /// - Returns: The resolved documentation entry.
    /// - Throws: An error if the documentation asset cannot be found, if the identifier does
    ///   not exist, or if the underlying storage backend fails to load the entry.
    public func fetch(_ identifier: String) throws -> FetchResult {
        let databaseDirectoryURL = try DocumentationAssetLocator().locateDatabaseDirectoryURL()

        let searchClient = try VectorSearchClient(databaseDirectoryURL: databaseDirectoryURL, readOnly: true)

        guard let result = try searchClient.fetch(identifier: identifier) else {
            throw BridgeError(.assetNotFound, "No documentation entry was found for \(identifier)")
        }

        return FetchResult(
            identifier: result.identifier,
            framework: result.framework,
            kind: result.type.flatMap(DocumentationKind.init(rawValue:)),
            title: result.title,
            content: result.content
        )
    }

    // MARK: Private

    private func embeddingVector(for text: String) async throws -> Data {
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

    private func makeFloat32Data(from float16Data: Data, expectedCount: Int) throws -> Data {
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
