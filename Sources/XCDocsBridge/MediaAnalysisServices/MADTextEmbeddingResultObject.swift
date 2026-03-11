import Foundation

package struct MADTextEmbeddingResultObject: PrivateObject {
  enum Key: String {
    case elementCount
    case embeddingData
  }

  let base: AnyObject

  init(base: AnyObject) {
    self.base = base
  }

  package var elementCount: Int {
    if let value: NSNumber = value(forKey: .elementCount, as: NSNumber.self) {
      return value.intValue
    }
    if let value: Int = value(forKey: .elementCount, as: Int.self) {
      return value
    }
    return 0
  }

  package var embeddingData: Data {
    if let data: Data = value(forKey: .embeddingData, as: Data.self) {
      return data
    }
    if let data: NSData = value(forKey: .embeddingData, as: NSData.self) {
      return data as Data
    }
    return Data()
  }
}
