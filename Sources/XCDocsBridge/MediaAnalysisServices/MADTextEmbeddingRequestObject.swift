import Foundation

package struct MADTextEmbeddingRequestObject: PrivateObject {
  enum Key: String {
    case embeddingResults
  }

  let base: AnyObject

  package init() throws {
    try FrameworkLoader.loadMediaAnalysisServices()
    let cls = try Self.requiredNSObjectClass(named: "MADTextEmbeddingRequest")
    self.base = cls.init()
  }

  package var embeddingResults: [MADTextEmbeddingResultObject] {
    array(forKey: .embeddingResults).map(MADTextEmbeddingResultObject.init(base:))
  }
}
