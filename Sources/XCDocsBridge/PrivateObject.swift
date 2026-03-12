import Foundation

enum DefaultKey: String { case key }

protocol PrivateObject {
    associatedtype Key: RawRepresentable = DefaultKey where Key.RawValue == String

    var base: AnyObject { get }
}

extension NSObject { fileprivate func xcdocsValue(forKey key: String) -> Any? { value(forKey: key) } }

extension PrivateObject {
    func value<T>(forKey key: String, as type: T.Type) -> T? { (base as? NSObject)?.xcdocsValue(forKey: key) as? T }

    func value<T>(forKey key: Key, as type: T.Type) -> T? { value(forKey: key.rawValue, as: type) }

    func value<T>(forKey key: String, as type: T.Type, default fallback: T) -> T {
        value(forKey: key, as: type) ?? fallback
    }

    func value<T>(forKey key: Key, as type: T.Type, default fallback: T) -> T {
        value(forKey: key.rawValue, as: type, default: fallback)
    }

    func array(forKey key: String) -> [AnyObject] {
        ((base as? NSObject)?.xcdocsValue(forKey: key) as? [AnyObject]) ?? []
    }

    func array(forKey key: Key) -> [AnyObject] { array(forKey: key.rawValue) }

    static func objcClassMethod<T>(_ cls: AnyClass, selector: Selector, as type: T.Type) -> T? {
        guard cls.responds(to: selector), let method = class_getClassMethod(cls, selector) else { return nil }
        return unsafeBitCast(method_getImplementation(method), to: T.self)
    }

    func objcInstanceMethod<T>(selector: Selector, as type: T.Type) -> T? {
        guard base.responds(to: selector) else { return nil }

        if let method = class_getInstanceMethod(Swift.type(of: base), selector) {
            return unsafeBitCast(method_getImplementation(method), to: T.self)
        }

        let imp = base.method(for: selector)
        return unsafeBitCast(imp, to: T.self)
    }

    static func requiredClass(named name: String) throws -> AnyClass {
        guard let cls = NSClassFromString(name) else {
            throw BridgeError(.classUnavailable, "Missing Objective-C class \(name)")
        }
        return cls
    }

    static func requiredNSObjectClass(named name: String) throws -> NSObject.Type {
        guard let cls = try requiredClass(named: name) as? NSObject.Type else {
            throw BridgeError(.classUnavailable, "\(name) is not an NSObject subclass")
        }
        return cls
    }

    static func allocateObject(of cls: AnyClass, className: String) throws -> AnyObject {
        guard let alloc: AllocMethod = objcClassMethod(cls, selector: xcdocsAllocSelector, as: AllocMethod.self) else {
            throw BridgeError(.selectorUnavailable, "Missing +alloc on \(className)")
        }
        return alloc(cls, xcdocsAllocSelector)
    }
}

private let xcdocsAllocSelector = NSSelectorFromString("alloc")

private typealias AllocMethod = @convention(c) (AnyClass, Selector) -> AnyObject
