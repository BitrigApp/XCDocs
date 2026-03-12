import Foundation

package struct VSKFilterObject: PrivateObject {
    let base: AnyObject

    package init(attribute: VSKAttributeObject, disjunctiveFilters: [VSKDisjunctiveFilterObject]) throws {
        try FrameworkLoader.loadVectorSearch()

        let cls: AnyClass = try Self.requiredClass(named: "VSKFilter")
        let rawObject = try Self.allocateObject(of: cls, className: "VSKFilter")

        guard
            let initialize = VSKFilterObject(base: rawObject).objcInstanceMethod(
                selector: Self.initSelector,
                as: VSKFilterInitMethod.self
            )
        else { throw BridgeError(.selectorUnavailable, "Missing -initWithAttribute:disjunctiveFilters: on VSKFilter") }

        guard
            let object = initialize(
                rawObject,
                Self.initSelector,
                attribute.base,
                disjunctiveFilters.map(\.base) as NSArray
            )
        else { throw BridgeError(.operationFailed, "Failed to create VSKFilter") }

        self.base = object
    }

    init(base: AnyObject) { self.base = base }

    private static let initSelector = NSSelectorFromString("initWithAttribute:disjunctiveFilters:")
}

private typealias VSKFilterInitMethod = @convention(c) (AnyObject, Selector, AnyObject, NSArray) -> AnyObject?
