import Foundation
import Testing
import XCDocs

@Suite("XCDocs Models") struct ModelTests {
    @Test func publicModelsRoundTripThroughCodable() throws {
        try assertRoundTrip(DocumentationKind.article)
        try assertRoundTrip(
            SearchResult(
                identifier: "/documentation/Testing",
                score: 0.75,
                framework: "Swift Testing",
                kind: .article,
                title: "Swift Testing",
                content: "Create and run tests."
            )
        )
        try assertRoundTrip(
            FetchResult(
                identifier: "/documentation/Testing",
                framework: "Swift Testing",
                kind: .article,
                title: "Swift Testing",
                content: "Create and run tests."
            )
        )
    }
}

private func assertRoundTrip<T: Codable & Equatable>(_ value: T) throws {
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(T.self, from: data)
    #expect(decoded == value)
}
