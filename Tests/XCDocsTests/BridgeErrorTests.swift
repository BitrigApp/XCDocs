import Foundation
import Testing

@testable import XCDocsBridge

@Suite("BridgeError")
struct BridgeErrorTests {
    @Test
    func formatsDescriptionWithoutUnderlyingError() {
        let error = BridgeError(.searchFailed, "Search failed")

        #expect(error.description == "[searchFailed] Search failed")
        #expect(error.errorDescription == "[searchFailed] Search failed")
    }

    @Test
    func formatsDescriptionWithEmptyMessage() {
        let error = BridgeError(.operationFailed, "")

        #expect(error.description == "[operationFailed] ")
        #expect(error.errorDescription == "[operationFailed] ")
    }

    @Test
    func formatsDescriptionForAllErrorCodes() {
        let codes: [BridgeErrorCode] = [
            .frameworkUnavailable, .classUnavailable, .selectorUnavailable, .assetNotFound, .invalidResponse,
            .invalidEmbedding, .operationFailed, .searchFailed, .timeout,
        ]

        for code in codes {
            let error = BridgeError(code, "msg")
            #expect(error.description == "[\(code.rawValue)] msg")
        }
    }

    @Test
    func formatsDescriptionWithUnderlyingError() {
        let underlyingError = NSError(domain: "Example", code: 7, userInfo: [NSLocalizedDescriptionKey: "Disk full"])
        let error = BridgeError(.operationFailed, "Operation failed", underlyingError: underlyingError)

        #expect(error.description == "[operationFailed] Operation failed (Disk full)")
        #expect(error.errorDescription == "[operationFailed] Operation failed (Disk full)")
    }
}
