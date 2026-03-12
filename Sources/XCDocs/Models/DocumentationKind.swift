import Foundation

/// Known documentation kinds exposed by Apple's local documentation search index.
public enum DocumentationKind: String, Codable, CaseIterable, Hashable, Sendable {
    /// A narrative documentation page.
    case article

    /// A symbol entry such as a framework, type, property, or method page.
    case symbol

    /// A topic section entry nested under a symbol or article.
    case topic
}
