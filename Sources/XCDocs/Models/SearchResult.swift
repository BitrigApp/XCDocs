import Foundation

/// A ranked documentation result returned from `Client.search`.
@available(macOS 26, *)
public struct SearchResult: Codable, Hashable, Identifiable, Sendable {
    /// The similarity score assigned by the underlying vector search engine.
    ///
    /// Higher values generally indicate a better semantic match.
    public let score: Double

    /// The documentation entry associated with the ranked result.
    public let entry: DocumentationEntry

    /// The stable identity for this result.
    public var id: String { entry.id }

    /// Creates a ranked search result.
    ///
    /// - Parameters:
    ///   - score: The similarity score from the search engine.
    ///   - entry: The documentation entry associated with the search hit.
    public init(score: Double, entry: DocumentationEntry) {
        self.score = score
        self.entry = entry
    }
}
