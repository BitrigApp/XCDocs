import Foundation

struct VSKColumnTypeObject: PrivateObject {
    let base: AnyObject

    init(defaultStringValue: String) throws {
        try FrameworkLoader.loadVectorSearch()

        let cls: AnyClass = try Self.requiredClass(named: "VSKColumnType")
        let rawObject = try Self.allocateObject(of: cls, className: "VSKColumnType")

        guard let initialize = VSKColumnTypeObject(base: rawObject).objcInstanceMethod(selector: Self.initSelector, as: VSKColumnTypeInitMethod.self) else { throw BridgeError(.selectorUnavailable, "Missing -initWithStringDefaultValue: on VSKColumnType") }

        guard let object = initialize(rawObject, Self.initSelector, defaultStringValue as NSString) else { throw BridgeError(.operationFailed, "Failed to create VSKColumnType") }

        self.base = object
    }

    init(base: AnyObject) { self.base = base }

    private static let initSelector = NSSelectorFromString("initWithStringDefaultValue:")
}

private typealias VSKColumnTypeInitMethod = @convention(c) (AnyObject, Selector, NSString) -> AnyObject?
