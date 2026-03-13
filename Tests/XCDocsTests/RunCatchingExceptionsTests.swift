import Foundation
import Testing

@testable import ExceptionCatcher

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
    func wrapsObjectiveCExceptionsAsNSError() throws {
        let error = try #require(
            captureNSError {
                try runCatchingExceptions {
                    NSException(name: .invalidArgumentException, reason: "boom", userInfo: nil).raise()
                }
            }
        )

        #expect(error.domain == "ExceptionCatcherObjC.Exception")
        #expect(error.code == 1)
        #expect(error.userInfo["XCDocsExceptionReason"] as? String == "boom")
    }

    @Test
    func preservesNilPathArgumentReason() throws {
        let error = try #require(
            captureNSError {
                try runCatchingExceptions {
                    NSException(name: .invalidArgumentException, reason: "nil path argument", userInfo: nil).raise()
                }
            }
        )

        #expect(error.userInfo["XCDocsExceptionReason"] as? String == "nil path argument")
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

private func captureNSError<T>(_ work: () throws -> T) -> NSError? {
    do {
        _ = try work()
        Issue.record("Expected NSError to be thrown.")
        return nil
    } catch let error as NSError { return error } catch {
        Issue.record("Unexpected error: \(String(describing: error))")
        return nil
    }
}
