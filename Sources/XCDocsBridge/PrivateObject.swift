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
        return validatedCast(method_getImplementation(method), method: method, to: type)
    }

    func objcInstanceMethod<T>(selector: Selector, as type: T.Type) -> T? {
        guard base.responds(to: selector) else { return nil }

        if let method = class_getInstanceMethod(Swift.type(of: base), selector) {
            return validatedCast(method_getImplementation(method), method: method, to: type)
        }

        let imp = base.method(for: selector)
        guard MemoryLayout<T>.size == MemoryLayout<IMP>.size else {
            logBitCastWarning(
                "Type \(T.self) size (\(MemoryLayout<T>.size)) does not match IMP size (\(MemoryLayout<IMP>.size))"
            )
            return nil
        }
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

private func logBitCastWarning(_ message: String) {
    #if DEBUG
    print("[XCDocsBridge] \(message)")
    #endif
}

private func validatedCast<T>(_ imp: IMP, method: Method, to type: T.Type) -> T? {
    guard MemoryLayout<T>.size == MemoryLayout<IMP>.size else {
        logBitCastWarning(
            "Type \(T.self) size (\(MemoryLayout<T>.size)) does not match IMP size (\(MemoryLayout<IMP>.size))"
        )
        return nil
    }

    let expectedArgs = method_getNumberOfArguments(method)
    let typeEncoding = String(cString: method_getTypeEncoding(method)!)
    let returnTypeEncoding = String(cString: method_copyReturnType(method))
    let isVoidReturn = returnTypeEncoding == "v"

    // Reject methods with fewer than the mandatory self + _cmd arguments,
    // which would indicate a corrupted or unexpected runtime entry.
    if expectedArgs < 2 {
        logBitCastWarning("ObjC method has fewer than 2 arguments (self, _cmd); type encoding: \(typeEncoding)")
        return nil
    }

    // If the method returns void but the caller expects a non-Void return value
    // in their @convention(c) signature, warn about the mismatch.
    if isVoidReturn {
        let typeName = String(describing: T.self)
        if !typeName.contains("Void") && !typeName.contains("()") {
            logBitCastWarning("ObjC method returns void but cast target \(T.self) may expect a return value")
        }
    }

    return unsafeBitCast(imp, to: T.self)
}
