import Foundation
import Testing

@testable import XCDocsSupport

@Suite("VectorSearchHit")
struct VectorSearchHitTests {
    @Test
    func mapsComputedPropertiesFromAttributes() {
        let hit = VectorSearchHit(
            identifier: "/documentation/Testing",
            score: 0.75,
            attributes: [
                "framework": "Swift Testing", "type": "article", "title": "Swift Testing",
                "content": "Create and run tests.",
            ]
        )

        #expect(hit.framework == "Swift Testing")
        #expect(hit.type == "article")
        #expect(hit.title == "Swift Testing")
        #expect(hit.content == "Create and run tests.")
    }

    @Test
    func roundTripsThroughCodable() throws {
        let original = VectorSearchHit(
            identifier: "/documentation/Testing",
            score: 0.75,
            attributes: ["framework": "Swift Testing", "type": "article", "title": "Swift Testing"]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(VectorSearchHit.self, from: data)

        #expect(decoded == original)
    }
}
