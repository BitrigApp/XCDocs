import Foundation

package struct BridgeError: Error, LocalizedError, CustomStringConvertible {
    let code: BridgeErrorCode
    let message: String
    let underlyingError: Error?

    package init(_ code: BridgeErrorCode, _ message: String) {
        self.code = code
        self.message = message
        self.underlyingError = nil
    }

    package init(_ code: BridgeErrorCode, _ message: String, underlyingError: Error?) {
        self.code = code
        self.message = message
        self.underlyingError = underlyingError
    }

    package var errorDescription: String? {
        description
    }

    package var description: String {
        if let underlyingError {
            return "[\(code.rawValue)] \(message) (\(underlyingError.localizedDescription))"
        }
        return "[\(code.rawValue)] \(message)"
    }
}
