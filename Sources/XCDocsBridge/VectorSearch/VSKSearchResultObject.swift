import Foundation

package struct VSKSearchResultObject: PrivateObject {
    enum Key: String {
        case identifier = "stringIdentifier"
        case score = "value"
        case attributes
    }

    let base: AnyObject

    init(base: AnyObject) { self.base = base }

    package var identifier: String { value(forKey: .identifier, as: String.self, default: "") }

    package var score: Double {
        get throws {
            if let number: NSNumber = value(forKey: .score, as: NSNumber.self) { return number.doubleValue }
            if let value: Double = value(forKey: .score, as: Double.self) { return value }
            throw BridgeError(.invalidScore, "Search result score could not be read as a numeric value")
        }
    }

    package var attributes: [String: String] {
        guard let attributeDictionary = value(forKey: .attributes, as: NSDictionary.self) else { return [:] }

        var result: [String: String] = [:]
        for (key, value) in attributeDictionary {
            let attribute = VSKAttributeObject(base: key as AnyObject)
            let databaseValue = VSKDatabaseValueObject(base: value as AnyObject)
            if let stringValue = databaseValue.stringValue { result[attribute.name] = stringValue }
        }
        return result
    }
}
