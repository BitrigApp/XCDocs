import Foundation

enum FrameworkLoader {
    static let mediaAnalysisServicesPath = "/System/Library/PrivateFrameworks/MediaAnalysisServices.framework"
    static let vectorSearchPath = "/System/Library/PrivateFrameworks/VectorSearch.framework"

    private static let mediaAnalysisServicesBundle = Result { try loadBundle(at: mediaAnalysisServicesPath) }

    private static let vectorSearchBundle = Result { try loadBundle(at: vectorSearchPath) }

    @discardableResult private static func loadBundle(at path: String) throws -> Bundle {
        guard let bundle = Bundle(path: path) else { throw BridgeError(.frameworkUnavailable, "Framework bundle missing at \(path)") }

        guard bundle.load() else { throw BridgeError(.frameworkUnavailable, "Failed to load framework at \(path)") }

        return bundle
    }

    @discardableResult static func loadMediaAnalysisServices() throws -> Bundle { try mediaAnalysisServicesBundle.get() }

    @discardableResult static func loadVectorSearch() throws -> Bundle { try vectorSearchBundle.get() }
}
