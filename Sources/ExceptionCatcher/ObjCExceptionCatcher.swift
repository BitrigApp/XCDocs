import ExceptionCatcherObjC
import Foundation

package func catchObjectiveCException(_ work: () -> Void) throws {
    if let error = XCDocsCatchException(work) as NSError? { throw error }
}
