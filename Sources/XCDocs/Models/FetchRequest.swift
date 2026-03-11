import Foundation

/// A request to fetch a documentation entry by its identifier.
public struct FetchRequest: Codable, Hashable, Sendable {
    /// The stable documentation identifier to resolve.
    ///
    /// This is typically a path-like identifier such as `/documentation/SwiftUI/Color`.
    public var identifier: String

    /// Creates a fetch request for a documentation identifier.
    ///
    /// - Parameter identifier: The identifier of the documentation entry to fetch.
    public init(identifier: String) {
        self.identifier = identifier
    }
}
