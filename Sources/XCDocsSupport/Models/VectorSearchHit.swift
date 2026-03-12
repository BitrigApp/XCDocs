import Foundation

package struct VectorSearchHit: Codable, Hashable, Sendable {
    package let identifier: String
    package let score: Double
    let attributes: [String: String]

    init(identifier: String, score: Double, attributes: [String: String]) {
        self.identifier = identifier
        self.score = score
        self.attributes = attributes
    }

    package var framework: String? { attributes["framework"] }

    package var type: String? { attributes["type"] }

    package var title: String? { attributes["title"] }

    package var content: String? { attributes["content"] }
}
