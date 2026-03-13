import Foundation
import Testing

@testable import XCDocsBridge

@Suite("PrivateObject")
struct PrivateObjectTests {
    @Test
    func readsValuesAndFallbacksViaKVC() async throws {
        let summary = await FixtureWrapper.valueSummary()

        #expect(summary.stringValue == "hello")
        #expect(summary.numberValue == 42)
        #expect(summary.fallbackValue == 7)
        #expect(summary.arrayCount == 2)
    }

    @Test
    func resolvesClassesAndAllocatesObjects() async throws {
        let summary = try await FixtureWrapper.classResolutionSummary()

        #expect(summary.classIdentifier == ObjectIdentifier(KeyValueFixture.self))
        #expect(summary.nsObjectClassIdentifier == ObjectIdentifier(KeyValueFixture.self))
        #expect(summary.allocatedTypeIdentifier == ObjectIdentifier(KeyValueFixture.self))
    }

    @Test
    func resolvesInstanceAndClassMethods() async throws {
        let summary = try await FixtureWrapper.methodResolutionSummary()

        #expect(summary.instanceAnswer == 42)
        #expect(summary.classAnswer == 7)
    }
}

private struct FixtureWrapper: PrivateObject {
    let base: AnyObject

    static func valueSummary() -> ValueSummary {
        let wrapper = FixtureWrapper(base: KeyValueFixture())
        return ValueSummary(
            stringValue: wrapper.value(forKey: "stringValue", as: String.self),
            numberValue: wrapper.value(forKey: "numberValue", as: NSNumber.self)?.intValue,
            fallbackValue: wrapper.value(forKey: "stringValue", as: Int.self, default: 7),
            arrayCount: wrapper.array(forKey: "objectArray").count
        )
    }

    static func classResolutionSummary() throws -> ClassResolutionSummary {
        let className = NSStringFromClass(KeyValueFixture.self)
        let cls: AnyClass = try requiredClass(named: className)
        let nsObjectClass = try requiredNSObjectClass(named: className)
        let allocatedObject = try allocateObject(of: cls, className: className)

        return ClassResolutionSummary(
            classIdentifier: ObjectIdentifier(cls),
            nsObjectClassIdentifier: ObjectIdentifier(nsObjectClass),
            allocatedTypeIdentifier: ObjectIdentifier(type(of: allocatedObject))
        )
    }

    static func methodResolutionSummary() throws -> MethodResolutionSummary {
        let fixture = KeyValueFixture()
        let wrapper = FixtureWrapper(base: fixture)
        let instanceSelector = NSSelectorFromString("answer")
        let classSelector = NSSelectorFromString("classAnswer")

        let instanceMethod = try #require(wrapper.objcInstanceMethod(selector: instanceSelector, as: NumberGetter.self))
        let classMethod = try #require(
            objcClassMethod(KeyValueFixture.self, selector: classSelector, as: ClassNumberGetter.self)
        )

        return MethodResolutionSummary(
            instanceAnswer: instanceMethod(fixture, instanceSelector)?.intValue,
            classAnswer: classMethod(KeyValueFixture.self, classSelector)?.intValue
        )
    }
}

private struct ValueSummary: Sendable {
    let stringValue: String?
    let numberValue: Int?
    let fallbackValue: Int
    let arrayCount: Int
}

private struct ClassResolutionSummary: Sendable {
    let classIdentifier: ObjectIdentifier
    let nsObjectClassIdentifier: ObjectIdentifier
    let allocatedTypeIdentifier: ObjectIdentifier
}

private struct MethodResolutionSummary: Sendable {
    let instanceAnswer: Int?
    let classAnswer: Int?
}

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
