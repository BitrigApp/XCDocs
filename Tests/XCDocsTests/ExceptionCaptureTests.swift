import ExceptionCatcherObjC
import Foundation
import Testing

@Suite("Objective-C Exception Capture")
struct ExceptionCaptureTests {
    @Test
    func returnsNilWhenWorkCompletesSuccessfully() {
        let error = XCDocsCatchException {}
        #expect(error == nil)
    }

    @Test
    func convertsRaisedExceptionsIntoNSError() throws {
        let error = XCDocsCatchException {
            NSException(name: .invalidArgumentException, reason: "boom", userInfo: nil).raise()
        }

        let nsError = try #require(error as NSError?)
        #expect(nsError.domain == "ExceptionCatcherObjC.Exception")
        #expect(nsError.code == 1)
    }

    @Test
    func handlesExceptionWithNilReason() throws {
        let error = XCDocsCatchException { NSException(name: .genericException, reason: nil, userInfo: nil).raise() }

        let nsError = try #require(error as NSError?)
        #expect(nsError.domain == "ExceptionCatcherObjC.Exception")
        #expect(nsError.code == 1)
        #expect(nsError.userInfo[NSLocalizedDescriptionKey] as? String == "Objective-C exception")
        #expect(nsError.userInfo["XCDocsExceptionReason"] == nil)
    }

    @Test
    func capturesRangeException() throws {
        let error = XCDocsCatchException {
            NSException(name: .rangeException, reason: "index out of bounds", userInfo: nil).raise()
        }

        let nsError = try #require(error as NSError?)
        #expect(nsError.userInfo["XCDocsExceptionName"] as? String == NSExceptionName.rangeException.rawValue)
        #expect(nsError.userInfo["XCDocsExceptionReason"] as? String == "index out of bounds")
    }

    @Test
    func capturesInternalInconsistencyException() throws {
        let error = XCDocsCatchException {
            NSException(name: .internalInconsistencyException, reason: "inconsistent state", userInfo: nil).raise()
        }

        let nsError = try #require(error as NSError?)
        #expect(
            nsError.userInfo["XCDocsExceptionName"] as? String
                == NSExceptionName.internalInconsistencyException.rawValue
        )
        #expect(nsError.userInfo["XCDocsExceptionReason"] as? String == "inconsistent state")
    }

    @Test
    func preservesExceptionNameAndReasonMetadata() throws {
        let error = XCDocsCatchException {
            NSException(name: .invalidArgumentException, reason: "bad argument", userInfo: nil).raise()
        }

        let nsError = try #require(error as NSError?)
        #expect(nsError.userInfo[NSLocalizedDescriptionKey] as? String == "bad argument")
        #expect(nsError.userInfo["XCDocsExceptionName"] as? String == NSExceptionName.invalidArgumentException.rawValue)
        #expect(nsError.userInfo["XCDocsExceptionReason"] as? String == "bad argument")
    }
}
