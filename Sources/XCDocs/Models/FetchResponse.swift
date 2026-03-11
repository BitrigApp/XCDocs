/// A response containing a fetched documentation entry.
public struct FetchResponse: Codable, Hashable, Sendable {
  /// The fetched documentation entry.
  public let result: FetchResult

  /// Creates a fetch response.
  ///
  /// - Parameter result: The fetched documentation entry.
  public init(result: FetchResult) {
    self.result = result
  }
}
