import ExceptionCatcherObjC
import Foundation
import Testing

@Suite("Objective-C Exception Capture") struct ExceptionCaptureTests {
    @Test func returnsNilWhenWorkCompletesSuccessfully() {
        let error = XCDocsCatchException {}
        #expect(error == nil)
    }

    @Test func convertsRaisedExceptionsIntoNSError() throws {
        let error = XCDocsCatchException {
            NSException(name: .invalidArgumentException, reason: "boom", userInfo: nil).raise()
        }

        let nsError = try #require(error as NSError?)
        #expect(nsError.domain == "ExceptionCatcherObjC.Exception")
        #expect(nsError.code == 1)
    }

    @Test func preservesExceptionNameAndReasonMetadata() throws {
        let error = XCDocsCatchException {
            NSException(name: .invalidArgumentException, reason: "bad argument", userInfo: nil).raise()
        }

        let nsError = try #require(error as NSError?)
        #expect(nsError.userInfo[NSLocalizedDescriptionKey] as? String == "bad argument")
        #expect(nsError.userInfo["XCDocsExceptionName"] as? String == NSExceptionName.invalidArgumentException.rawValue)
        #expect(nsError.userInfo["XCDocsExceptionReason"] as? String == "bad argument")
    }
}
