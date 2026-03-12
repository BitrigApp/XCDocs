import Foundation

package final class MADServiceObject: PrivateObject {
    let base: AnyObject

    package init() throws {
        try FrameworkLoader.loadMediaAnalysisServices()
        let cls: AnyClass = try Self.requiredClass(named: "MADService")

        guard let makeService = Self.objcClassMethod(cls, selector: Self.serviceSelector, as: MADServiceFactoryMethod.self) else { throw BridgeError(.selectorUnavailable, "Missing +service on MADService") }

        guard let object = makeService(cls, Self.serviceSelector) else { throw BridgeError(.operationFailed, "Failed to create MADService via +service") }

        self.base = object
    }

    @discardableResult package func performRequests(requests: [MADTextEmbeddingRequestObject], textInputs: [MADTextInputObject], completionHandler: AnyObject?) throws -> Int32 {
        guard let method = objcInstanceMethod(selector: Self.performRequestsSelector, as: MADServicePerformRequestsMethod.self) else { throw BridgeError(.selectorUnavailable, "Missing -performRequests:textInputs:completionHandler: on MADService") }

        let requestID = method(base, Self.performRequestsSelector, requests.map(\.base) as NSArray, textInputs.map(\.base) as NSArray, completionHandler)

        if requestID < 0 { throw BridgeError(.operationFailed, "MADService returned invalid request ID \(requestID)") }

        return requestID
    }

    private static let performRequestsSelector = NSSelectorFromString("performRequests:textInputs:completionHandler:")
    private static let serviceSelector = NSSelectorFromString("service")
}

private typealias MADServiceFactoryMethod = @convention(c) (AnyClass, Selector) -> AnyObject?

private typealias MADServicePerformRequestsMethod = @convention(c) (AnyObject, Selector, NSArray, NSArray, AnyObject?) -> Int32
