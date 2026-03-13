import ExceptionCatcher
import Foundation
import Testing

@Suite("Objective-C Exception Capture")
struct ExceptionCaptureTests {
    @Test
    func returnsNilWhenWorkCompletesSuccessfully() throws { try catchObjectiveCException {} }

    @Test
    func convertsRaisedExceptionsIntoNSError() throws {
        let nsError = try #require(
            captureNSError {
                try catchObjectiveCException {
                    NSException(name: .invalidArgumentException, reason: "boom", userInfo: nil).raise()
                }
            }
        )
        #expect(nsError.domain == "ExceptionCatcherObjC.Exception")
        #expect(nsError.code == 1)
    }

    @Test
    func handlesExceptionWithNilReason() throws {
        let nsError = try #require(
            captureNSError {
                try catchObjectiveCException {
                    NSException(name: .genericException, reason: nil, userInfo: nil).raise()
                }
            }
        )
        #expect(nsError.domain == "ExceptionCatcherObjC.Exception")
        #expect(nsError.code == 1)
        #expect(nsError.userInfo[NSLocalizedDescriptionKey] as? String == "Objective-C exception")
        #expect(nsError.userInfo["XCDocsExceptionReason"] == nil)
    }

    @Test
    func capturesRangeException() throws {
        let nsError = try #require(
            captureNSError {
                try catchObjectiveCException {
                    NSException(name: .rangeException, reason: "index out of bounds", userInfo: nil).raise()
                }
            }
        )
        #expect(nsError.userInfo["XCDocsExceptionName"] as? String == NSExceptionName.rangeException.rawValue)
        #expect(nsError.userInfo["XCDocsExceptionReason"] as? String == "index out of bounds")
    }

    @Test
    func capturesInternalInconsistencyException() throws {
        let nsError = try #require(
            captureNSError {
                try catchObjectiveCException {
                    NSException(name: .internalInconsistencyException, reason: "inconsistent state", userInfo: nil)
                        .raise()
                }
            }
        )
        #expect(
            nsError.userInfo["XCDocsExceptionName"] as? String
                == NSExceptionName.internalInconsistencyException.rawValue
        )
        #expect(nsError.userInfo["XCDocsExceptionReason"] as? String == "inconsistent state")
    }

    @Test
    func preservesExceptionNameAndReasonMetadata() throws {
        let nsError = try #require(
            captureNSError {
                try catchObjectiveCException {
                    NSException(name: .invalidArgumentException, reason: "bad argument", userInfo: nil).raise()
                }
            }
        )
        #expect(nsError.userInfo[NSLocalizedDescriptionKey] as? String == "bad argument")
        #expect(nsError.userInfo["XCDocsExceptionName"] as? String == NSExceptionName.invalidArgumentException.rawValue)
        #expect(nsError.userInfo["XCDocsExceptionReason"] as? String == "bad argument")
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
