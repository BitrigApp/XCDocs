import Foundation

package struct VSKConfigObject: PrivateObject {
    let base: AnyObject

    package init(baseDirectoryURL: URL, numberOfProbes: Int, readOnly: Bool) throws {
        try FrameworkLoader.loadVectorSearch()

        let cls: AnyClass = try Self.requiredClass(named: "VSKConfig")
        let rawObject = try Self.allocateObject(of: cls, className: "VSKConfig")

        guard
            let initialize = VSKConfigObject(base: rawObject).objcInstanceMethod(
                selector: Self.initSelector,
                as: VSKConfigInitMethod.self
            )
        else {
            throw BridgeError(
                .selectorUnavailable,
                "Missing -initWithBaseDirectory:includePayload:numberOfProbes:readOnly:error: on VSKConfig"
            )
        }

        var errorObject: AnyObject?
        guard
            let object = initialize(
                rawObject,
                Self.initSelector,
                baseDirectoryURL as NSURL,
                false,
                NSNumber(value: numberOfProbes),
                readOnly,
                &errorObject
            )
        else {
            throw BridgeError(
                .operationFailed,
                "Failed to create VSKConfig for \(baseDirectoryURL.path)",
                underlyingError: errorObject as? Error
            )
        }

        if let errorObject = errorObject as? Error {
            throw BridgeError(
                .operationFailed,
                "VSKConfig initialization reported an error for \(baseDirectoryURL.path)",
                underlyingError: errorObject
            )
        }

        self.base = object
    }

    init(base: AnyObject) { self.base = base }

    private static let initSelector = NSSelectorFromString(
        "initWithBaseDirectory:includePayload:numberOfProbes:readOnly:error:"
    )
}

private typealias VSKConfigInitMethod =
    @convention(c) (AnyObject, Selector, NSURL, Bool, NSNumber, Bool, UnsafeMutablePointer<AnyObject?>?) -> AnyObject?
