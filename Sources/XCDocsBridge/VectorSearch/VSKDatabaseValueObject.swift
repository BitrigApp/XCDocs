import Foundation

package struct VSKDatabaseValueObject: PrivateObject {
    let base: AnyObject

    init(base: AnyObject) { self.base = base }

    package init(string: String) throws {
        try FrameworkLoader.loadVectorSearch()

        let cls: AnyClass = try Self.requiredClass(named: "VSKDatabaseValue")
        let rawObject = try Self.allocateObject(of: cls, className: "VSKDatabaseValue")

        guard let initialize = VSKDatabaseValueObject(base: rawObject).objcInstanceMethod(selector: Self.initWithStringSelector, as: VSKDatabaseValueInitWithStringMethod.self) else { throw BridgeError(.selectorUnavailable, "Missing -initWithStringValue: on VSKDatabaseValue") }

        guard let object = initialize(rawObject, Self.initWithStringSelector, string as NSString) else { throw BridgeError(.operationFailed, "Failed to create VSKDatabaseValue") }

        self.base = object
    }

    var stringValue: String? {
        guard let getter = objcInstanceMethod(selector: Self.getStringSelector, as: VSKDatabaseValueGetStringMethod.self) else { return nil }
        return getter(base, Self.getStringSelector) as String?
    }

    private static let initWithStringSelector = NSSelectorFromString("initWithStringValue:")
    private static let getStringSelector = NSSelectorFromString("getStringValue")
}

private typealias VSKDatabaseValueInitWithStringMethod = @convention(c) (AnyObject, Selector, NSString) -> AnyObject?

private typealias VSKDatabaseValueGetStringMethod = @convention(c) (AnyObject, Selector) -> NSString?
