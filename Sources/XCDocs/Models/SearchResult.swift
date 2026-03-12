import Foundation

/// A ranked documentation result returned from `Client.search`.
@available(macOS 26, *) public struct SearchResult: Codable, Hashable, Sendable {
    /// The stable documentation identifier for the result.
    public let identifier: String

    /// The similarity score assigned by the underlying vector search engine.
    ///
    /// Higher values generally indicate a better semantic match.
    public let score: Double

    /// The framework or documentation collection that owns the result, if known.
    public let framework: String?

    /// The entry kind reported by the documentation database, if known.
    public let kind: DocumentationKind?

    /// The display title for the result, if present.
    public let title: String?

    /// The entry content, if it was requested and available.
    public let content: String?

    /// Creates a ranked search result.
    ///
    /// - Parameters:
    ///   - identifier: The stable documentation identifier for the result.
    ///   - score: The similarity score from the search engine.
    ///   - framework: The framework or collection that owns the result, if known.
    ///   - kind: The entry classification reported by the documentation asset, if known.
    ///   - title: The display title for the result, if present.
    ///   - content: The entry content, if requested and available.
    public init(
        identifier: String,
        score: Double,
        framework: String?,
        kind: DocumentationKind?,
        title: String?,
        content: String?
    ) {
        self.identifier = identifier
        self.score = score
        self.framework = framework
        self.kind = kind
        self.title = title
        self.content = content
    }
}
