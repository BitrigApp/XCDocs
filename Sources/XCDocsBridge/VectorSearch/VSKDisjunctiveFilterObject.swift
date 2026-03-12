import Foundation

package struct VSKDisjunctiveFilterObject: PrivateObject {
    let base: AnyObject

    package init(operatorRawValue: Int64, value: VSKDatabaseValueObject) throws {
        try FrameworkLoader.loadVectorSearch()

        let cls: AnyClass = try Self.requiredClass(named: "VSKDisjunctiveFilter")
        let rawObject = try Self.allocateObject(of: cls, className: "VSKDisjunctiveFilter")

        guard
            let initialize = VSKDisjunctiveFilterObject(base: rawObject).objcInstanceMethod(
                selector: Self.initSelector,
                as: VSKDisjunctiveFilterInitMethod.self
            )
        else { throw BridgeError(.selectorUnavailable, "Missing -initWithOperator:value: on VSKDisjunctiveFilter") }

        guard let object = initialize(rawObject, Self.initSelector, operatorRawValue, value.base) else {
            throw BridgeError(.operationFailed, "Failed to create VSKDisjunctiveFilter")
        }

        self.base = object
    }

    init(base: AnyObject) { self.base = base }

    private static let initSelector = NSSelectorFromString("initWithOperator:value:")
}

private typealias VSKDisjunctiveFilterInitMethod = @convention(c) (AnyObject, Selector, Int64, AnyObject) -> AnyObject?
