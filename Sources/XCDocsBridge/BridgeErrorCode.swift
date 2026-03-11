package enum BridgeErrorCode: String, Sendable {
  case frameworkUnavailable
  case classUnavailable
  case selectorUnavailable
  case assetNotFound
  case invalidResponse
  case invalidEmbedding
  case operationFailed
  case searchFailed
  case timeout
}
