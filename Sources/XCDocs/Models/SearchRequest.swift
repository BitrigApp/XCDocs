import Foundation

/// A request to semantically search Apple's local documentation database.
public struct SearchRequest: Codable, Hashable, Sendable {
  /// The natural-language query to search for.
  public var query: String

  /// Framework names to restrict results to.
  ///
  /// When empty, the search spans all indexed documentation.
  public var frameworks: [String]

  /// Result kinds to restrict results to.
  ///
  /// When empty, the search includes all documentation entry kinds.
  public var kinds: [DocumentationKind]

  /// The maximum number of results to return.
  public var maxResults: Int

  /// Whether each result should include the entry's full content when available.
  ///
  /// Enabling this can return significantly more text in the response, but is useful when
  /// the caller wants the same content that Xcode's MCP documentation tool returns.
  public var includeContent: Bool

  /// Creates a semantic documentation search request.
  ///
  /// - Parameters:
  ///   - query: The natural-language search query.
  ///   - frameworks: Optional framework filters to constrain the search.
  ///   - kinds: Optional kind filters such as ``DocumentationKind/article``,
  ///     ``DocumentationKind/symbol``, or ``DocumentationKind/topic``.
  ///   - maxResults: The maximum number of ranked matches to return.
  ///   - includeContent: Whether result payloads should include full entry content when
  ///     available.
  public init(
    query: String,
    frameworks: [String] = [],
    kinds: [DocumentationKind] = [],
    maxResults: Int = 10,
    includeContent: Bool = false
  ) {
    self.query = query
    self.frameworks = frameworks
    self.kinds = kinds
    self.maxResults = maxResults
    self.includeContent = includeContent
  }
}
