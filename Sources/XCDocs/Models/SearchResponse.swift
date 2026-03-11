import Foundation

/// A semantic search response returned from ``Client/search(_:)``.
public struct SearchResponse: Codable, Hashable, Sendable {
  /// The original query string that produced these results.
  public let query: String

  /// The ranked documentation results for the query.
  public let results: [SearchResult]

  /// Creates a search response.
  ///
  /// - Parameters:
  ///   - query: The original query string.
  ///   - results: The ranked results for that query.
  public init(
    query: String,
    results: [SearchResult]
  ) {
    self.query = query
    self.results = results
  }
}
