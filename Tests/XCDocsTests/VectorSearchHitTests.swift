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
    func returnsNilForMissingAttributes() {
        let hit = VectorSearchHit(
            identifier: "/documentation/Testing",
            score: 0.75,
            attributes: ["framework": "Swift Testing"]
        )

        #expect(hit.content == nil)
        #expect(hit.title == nil)
        #expect(hit.type == nil)
    }

    @Test
    func returnsEmptyStringForEmptyAttributeValues() {
        let hit = VectorSearchHit(
            identifier: "/documentation/Testing",
            score: 0.0,
            attributes: ["framework": "", "type": "", "title": "", "content": ""]
        )

        #expect(hit.framework == "")
        #expect(hit.type == "")
        #expect(hit.title == "")
        #expect(hit.content == "")
    }

    @Test
    func decodesFromPartialJSON() throws {
        let json = """
            {"identifier":"/doc/X","score":0.5,"attributes":{}}
            """
        let data = Data(json.utf8)
        let hit = try JSONDecoder().decode(VectorSearchHit.self, from: data)

        #expect(hit.identifier == "/doc/X")
        #expect(hit.score == 0.5)
        #expect(hit.framework == nil)
        #expect(hit.title == nil)
        #expect(hit.type == nil)
        #expect(hit.content == nil)
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
