import ExceptionCatcherObjC
import Foundation

package enum ExceptionCatcherError: Error { case missingResult }

package func catchObjectiveCException(_ work: () -> Void) throws {
    if let error = XCDocsCatchException(work) as NSError? { throw error }
}

package func runCatchingExceptions<T>(_ work: () throws -> T) throws -> T {
    var result: Result<T, Error>?
    try catchObjectiveCException { do { result = .success(try work()) } catch { result = .failure(error) } }

    guard let result else { throw ExceptionCatcherError.missingResult }

    return try result.get()
}
