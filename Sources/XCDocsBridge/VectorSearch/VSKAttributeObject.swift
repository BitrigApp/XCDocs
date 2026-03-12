import Foundation

package struct VSKAttributeObject: PrivateObject {
    let base: AnyObject

    init(base: AnyObject) { self.base = base }

    init(name: String, columnType: VSKColumnTypeObject) throws {
        try FrameworkLoader.loadVectorSearch()

        let cls: AnyClass = try Self.requiredClass(named: "VSKAttribute")
        let rawObject = try Self.allocateObject(of: cls, className: "VSKAttribute")

        guard
            let initialize = VSKAttributeObject(base: rawObject).objcInstanceMethod(
                selector: Self.initSelector,
                as: VSKAttributeInitMethod.self
            )
        else { throw BridgeError(.selectorUnavailable, "Missing -initWithName:columnType: on VSKAttribute") }

        guard let object = initialize(rawObject, Self.initSelector, name as NSString, columnType.base) else {
            throw BridgeError(.operationFailed, "Failed to create VSKAttribute \(name)")
        }

        self.base = object
    }

    package static func stringNamed(_ name: String) throws -> VSKAttributeObject {
        try VSKAttributeObject(name: name, columnType: VSKColumnTypeObject(defaultStringValue: ""))
    }

    package var name: String {
        guard let getter = objcInstanceMethod(selector: Self.getNameSelector, as: VSKAttributeGetNameMethod.self) else {
            return ""
        }
        return getter(base, Self.getNameSelector) as String? ?? ""
    }

    private static let initSelector = NSSelectorFromString("initWithName:columnType:")
    private static let getNameSelector = NSSelectorFromString("getName")
}

private typealias VSKAttributeInitMethod = @convention(c) (AnyObject, Selector, NSString, AnyObject) -> AnyObject?

private typealias VSKAttributeGetNameMethod = @convention(c) (AnyObject, Selector) -> NSString?
