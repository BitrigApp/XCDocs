import XCDocsExceptionCatcher
import Foundation

package final class MADServiceObject: PrivateObject {
    let base: AnyObject

    package init() throws {
        try FrameworkLoader.loadMediaAnalysisServices()
        let cls: AnyClass = try Self.requiredClass(named: "MADService")

        guard
            let makeService = Self.objcClassMethod(
                cls,
                selector: Self.serviceSelector,
                as: MADServiceFactoryMethod.self
            )
        else { throw BridgeError(.selectorUnavailable, "Missing +service on MADService") }

        guard let object = makeService(cls, Self.serviceSelector) else {
            throw BridgeError(.operationFailed, "Failed to create MADService via +service")
        }

        self.base = object
    }

    @discardableResult
    package func performRequests(_ requests: [MADTextEmbeddingRequestObject], textInputs: [MADTextInputObject])
        async throws -> Int32
    {
        var requestID: Int32 = 0

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            let completionHandler: @convention(block) () -> Void = { continuation.resume() }

            do {
                try catchObjectiveCException {
                    do {
                        guard
                            let method = objcInstanceMethod(
                                selector: Self.performRequestsSelector,
                                as: MADServicePerformRequestsMethod.self
                            )
                        else {
                            throw BridgeError(
                                .selectorUnavailable,
                                "Missing -performRequests:textInputs:completionHandler: on MADService"
                            )
                        }

                        requestID = method(
                            base,
                            Self.performRequestsSelector,
                            requests.map(\.base) as NSArray,
                            textInputs.map(\.base) as NSArray,
                            completionHandler as AnyObject
                        )

                        if requestID < 0 {
                            throw BridgeError(.operationFailed, "MADService returned invalid request ID \(requestID)")
                        }
                    } catch { continuation.resume(throwing: error) }
                }
            } catch let nsError as NSError {
                continuation.resume(
                    throwing: BridgeError(.operationFailed, Self.message(for: nsError), underlyingError: nsError)
                )
            }
        }

        return requestID
    }

    private static let performRequestsSelector = NSSelectorFromString("performRequests:textInputs:completionHandler:")
    private static let serviceSelector = NSSelectorFromString("service")

    private static func message(for error: NSError) -> String {
        let reason = error.userInfo["XCDocsExceptionReason"] as? String ?? error.localizedDescription
        if reason.contains("nil path argument") {
            return "MediaAnalysisServices failed to bootstrap its XPC connection."
        }
        return "Objective-C exception while calling MediaAnalysisServices."
    }
}

private typealias MADServiceFactoryMethod = @convention(c) (AnyClass, Selector) -> AnyObject?

private typealias MADServicePerformRequestsMethod =
    @convention(c) (AnyObject, Selector, NSArray, NSArray, AnyObject?) -> Int32
