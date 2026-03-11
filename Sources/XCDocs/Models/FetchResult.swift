import Foundation

/// A single documentation entry returned from ``Client/fetch(_:)``.
public struct FetchResult: Codable, Hashable, Sendable {
  /// The stable documentation identifier for the entry.
  public let identifier: String

  /// The framework or documentation collection that owns the entry, if known.
  public let framework: String?

  /// The entry kind reported by the documentation database, if known.
  public let kind: DocumentationKind?

  /// The display title for the entry, if present.
  public let title: String?

  /// The full rendered content for the entry, if present.
  public let content: String?

  /// Creates a fetched documentation result.
  ///
  /// - Parameters:
  ///   - identifier: The stable documentation identifier for the entry.
  ///   - framework: The framework or collection that owns the entry, if known.
  ///   - kind: The entry classification reported by the documentation asset, if known.
  ///   - title: The display title for the entry, if present.
  ///   - content: The full textual content for the entry, if present.
  public init(
    identifier: String,
    framework: String?,
    kind: DocumentationKind?,
    title: String?,
    content: String?
  ) {
    self.identifier = identifier
    self.framework = framework
    self.kind = kind
    self.title = title
    self.content = content
  }
}
