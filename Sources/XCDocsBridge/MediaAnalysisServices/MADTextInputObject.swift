import Foundation

package struct MADTextInputObject: PrivateObject {
    let base: AnyObject

    init(base: AnyObject) {
        self.base = base
    }

    package init(text: String) throws {
        try FrameworkLoader.loadMediaAnalysisServices()

        let cls: AnyClass = try Self.requiredClass(named: "MADTextInput")
        let rawObject = try Self.allocateObject(of: cls, className: "MADTextInput")

        guard let initialize = MADTextInputObject(base: rawObject).objcInstanceMethod(
            selector: Self.initSelector,
            as: MADTextInputInitMethod.self
        ) else {
            throw BridgeError(.selectorUnavailable, "Missing -initWithText: on MADTextInput")
        }

        guard let object = initialize(rawObject, Self.initSelector, text as NSString) else {
            throw BridgeError(.operationFailed, "Failed to create MADTextInput")
        }

        self.base = object
    }

    private static let initSelector = NSSelectorFromString("initWithText:")
}

private typealias MADTextInputInitMethod =
    @convention(c) (AnyObject, Selector, NSString) -> AnyObject?
