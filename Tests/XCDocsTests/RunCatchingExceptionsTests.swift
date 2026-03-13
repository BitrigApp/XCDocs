import Foundation
import Testing

@testable import ExceptionCatcher
@testable import XCDocsBridge

@Suite("runCatchingExceptions")
struct RunCatchingExceptionsTests {
    @Test
    func returnsSuccessfulValues() throws {
        let value = try runCatchingExceptions { 42 }
        #expect(value == 42)
    }

    @Test
    func propagatesSwiftErrorsUnchanged() {
        let error = captureFixtureError { try runCatchingExceptions { throw FixtureError.sample } }

        #expect(error == .sample)
    }

    @Test
    func wrapsObjectiveCExceptionsAsBridgeErrors() throws {
        let error = try #require(
            captureBridgeError {
                try runCatchingExceptions {
                    NSException(name: .invalidArgumentException, reason: "boom", userInfo: nil).raise()
                }
            }
        )

        #expect(error.code == .operationFailed)
        #expect(error.message == "Objective-C exception while calling MediaAnalysisServices.")
        #expect((error.underlyingError as NSError?)?.userInfo["XCDocsExceptionReason"] as? String == "boom")
    }

    @Test
    func mapsNilPathArgumentExceptionsToBootstrapMessage() throws {
        let error = try #require(
            captureBridgeError {
                try runCatchingExceptions {
                    NSException(name: .invalidArgumentException, reason: "nil path argument", userInfo: nil).raise()
                }
            }
        )

        #expect(error.code == .operationFailed)
        #expect(error.message == "MediaAnalysisServices failed to bootstrap its XPC connection.")
    }
}

private enum FixtureError: Error, Equatable { case sample }

private func captureFixtureError<T>(_ work: () throws -> T) -> FixtureError? {
    do {
        _ = try work()
        Issue.record("Expected FixtureError to be thrown.")
        return nil
    } catch let error as FixtureError { return error } catch {
        Issue.record("Unexpected error: \(String(describing: error))")
        return nil
    }
}

private func captureBridgeError<T>(_ work: () throws -> T) -> BridgeError? {
    do {
        _ = try work()
        Issue.record("Expected BridgeError to be thrown.")
        return nil
    } catch let error as BridgeError { return error } catch {
        Issue.record("Unexpected error: \(String(describing: error))")
        return nil
    }
}
