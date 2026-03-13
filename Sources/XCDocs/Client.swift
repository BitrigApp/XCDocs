import Foundation
import XCDocsBridge
import XCDocsSupport

/// A high-level client for searching and fetching Apple's local developer documentation.
///
/// `Client` locates the on-disk documentation asset that ships with Xcode and macOS,
/// generates semantic query embeddings using Apple's private embedding service, and
/// resolves search results into stable Swift value types.
@available(macOS 26, *)
public final class Client {
    private var cachedSearchClient: VectorSearchClient?

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
        let searchClient = try await searchClient()
        let vector = try await embeddingVector(for: query)

        let hits = try await searchClient.search(
            vector: vector,
            frameworks: frameworks,
            kinds: kinds.map(\.rawValue),
            limit: limit,
            omitContent: omitContent
        )

        return hits.map {
            SearchResult(
                score: $0.score,
                entry: DocumentationEntry(
                    id: $0.identifier,
                    framework: $0.framework,
                    kind: $0.type.flatMap(DocumentationKind.init(rawValue:)),
                    title: $0.title,
                    content: $0.content
                )
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
    public func fetch(_ identifier: String) async throws -> DocumentationEntry {
        let searchClient = try await searchClient()
        let result = try await searchClient.fetch(identifier: identifier)

        return DocumentationEntry(
            id: result.identifier,
            framework: result.framework,
            kind: result.type.flatMap(DocumentationKind.init(rawValue:)),
            title: result.title,
            content: result.content
        )
    }

    // MARK: Private

    private func searchClient() async throws -> VectorSearchClient {
        if let cachedSearchClient { return cachedSearchClient }

        let databaseDirectoryURL = try DocumentationAssetLocator().locateDatabaseDirectoryURL()
        let client = try await VectorSearchClient(databaseDirectoryURL: databaseDirectoryURL, readOnly: true)
        cachedSearchClient = client
        return client
    }

    private func embeddingVector(for text: String) async throws -> Data {
        let service = try await MADServiceObject()
        let request = try await MADTextEmbeddingRequestObject()
        let textInput = try await MADTextInputObject(text: text)

        _ = try await service.performRequests(requests: [request], textInputs: [textInput])

        return try await request.float32EmbeddingData()
    }
}
