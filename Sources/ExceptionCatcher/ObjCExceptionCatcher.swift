import ExceptionCatcherObjC
import Foundation
import XCDocsBridge

package func runCatchingExceptions<T>(_ work: () throws -> T) throws -> T {
    var result: Result<T, Error>?
    let exceptionError = XCDocsCatchException {
        do {
            result = .success(try work())
        } catch {
            result = .failure(error)
        }
    }

    if let exceptionError {
        let nsError = exceptionError as NSError
        throw BridgeError(
            .operationFailed,
            message(for: nsError),
            underlyingError: nsError
        )
    }

    guard let result else {
        throw BridgeError(
            .operationFailed,
            "Objective-C wrapper completed without a value or error."
        )
    }

    return try result.get()
}

private func message(for error: NSError) -> String {
    let reason = error.userInfo["XCDocsExceptionReason"] as? String ?? error.localizedDescription
    if reason.contains("nil path argument") {
        return "MediaAnalysisServices failed to bootstrap its XPC connection."
    }
    return "Objective-C exception while calling MediaAnalysisServices."
}
