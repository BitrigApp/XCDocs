import Foundation
import Testing

@testable import XCDocsBridge

@Suite("PrivateObject")
struct PrivateObjectTests {
    @Test
    func readsValuesAndFallbacksViaKVC() {
        let fixture = KeyValueFixture()
        let wrapper = FixtureWrapper(base: fixture)

        #expect(wrapper.value(forKey: "stringValue", as: String.self) == "hello")
        #expect(wrapper.value(forKey: "numberValue", as: NSNumber.self)?.intValue == 42)
        #expect(wrapper.value(forKey: "stringValue", as: Int.self, default: 7) == 7)
        #expect(wrapper.array(forKey: "objectArray").count == 2)
    }

    @Test
    func resolvesClassesAndAllocatesObjects() throws {
        let className = NSStringFromClass(KeyValueFixture.self)
        let cls: AnyClass = try FixtureWrapper.requiredClass(named: className)
        let nsObjectClass = try FixtureWrapper.requiredNSObjectClass(named: className)
        let allocatedObject = try FixtureWrapper.allocateObject(of: cls, className: className)

        #expect(ObjectIdentifier(cls) == ObjectIdentifier(KeyValueFixture.self))
        #expect(ObjectIdentifier(nsObjectClass) == ObjectIdentifier(KeyValueFixture.self))
        #expect(ObjectIdentifier(type(of: allocatedObject)) == ObjectIdentifier(KeyValueFixture.self))
    }

    @Test
    func resolvesInstanceAndClassMethods() throws {
        let fixture = KeyValueFixture()
        let wrapper = FixtureWrapper(base: fixture)
        let instanceSelector = NSSelectorFromString("answer")
        let classSelector = NSSelectorFromString("classAnswer")

        let instanceMethod = try #require(wrapper.objcInstanceMethod(selector: instanceSelector, as: NumberGetter.self))
        let classMethod = try #require(
            FixtureWrapper.objcClassMethod(KeyValueFixture.self, selector: classSelector, as: ClassNumberGetter.self)
        )

        #expect(instanceMethod(fixture, instanceSelector)?.intValue == 42)
        #expect(classMethod(KeyValueFixture.self, classSelector)?.intValue == 7)
    }

    @Test
    func returnsNilForNonExistentSelector() {
        let fixture = KeyValueFixture()
        let wrapper = FixtureWrapper(base: fixture)
        let bogusSelector = NSSelectorFromString("totallyBogusMethod")

        let result = wrapper.objcInstanceMethod(selector: bogusSelector, as: NumberGetter.self)
        #expect(result == nil)
    }

    @Test
    func returnsNilForNonExistentClassSelector() {
        let bogusSelector = NSSelectorFromString("totallyBogusClassMethod")

        let result = FixtureWrapper.objcClassMethod(
            KeyValueFixture.self,
            selector: bogusSelector,
            as: ClassNumberGetter.self
        )
        #expect(result == nil)
    }

    @Test
    func returnsNilWhenTargetTypeSizeDoesNotMatchIMP() {
        let fixture = KeyValueFixture()
        let wrapper = FixtureWrapper(base: fixture)
        let selector = NSSelectorFromString("answer")

        // OversizedType is larger than a pointer, so the cast should be rejected.
        let result = wrapper.objcInstanceMethod(selector: selector, as: OversizedType.self)
        #expect(result == nil)
    }

    @Test
    func returnsNilWhenClassMethodTargetTypeSizeDoesNotMatchIMP() {
        let selector = NSSelectorFromString("classAnswer")

        let result = FixtureWrapper.objcClassMethod(KeyValueFixture.self, selector: selector, as: OversizedType.self)
        #expect(result == nil)
    }
}

private struct FixtureWrapper: PrivateObject { let base: AnyObject }

@objcMembers
private final class KeyValueFixture: NSObject {
    dynamic var stringValue = "hello"
    dynamic var numberValue = NSNumber(value: 42)
    dynamic var objectArray: [AnyObject] = ["first" as NSString, NSNumber(value: 2)]

    dynamic func answer() -> NSNumber { NSNumber(value: 42) }

    class dynamic func classAnswer() -> NSNumber { NSNumber(value: 7) }
}

private typealias NumberGetter = @convention(c) (AnyObject, Selector) -> NSNumber?
private typealias ClassNumberGetter = @convention(c) (AnyClass, Selector) -> NSNumber?

/// A type whose size exceeds that of a function pointer, used to verify that
/// `validatedCast` rejects size-mismatched bit casts.
private struct OversizedType {
    let a: UInt64
    let b: UInt64
    let c: UInt64
}
