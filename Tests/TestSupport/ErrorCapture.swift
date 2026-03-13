import Testing
import XCDocsBridge

package func captureBridgeError<T>(_ work: () throws -> T) -> BridgeError? {
    do {
        _ = try work()
        Issue.record("Expected BridgeError to be thrown.")
        return nil
    } catch let error as BridgeError { return error } catch {
        Issue.record("Unexpected error: \(String(describing: error))")
        return nil
    }
}

package func captureBridgeError<T>(_ work: () async throws -> T) async -> BridgeError? {
    do {
        _ = try await work()
        Issue.record("Expected BridgeError to be thrown.")
        return nil
    } catch let error as BridgeError { return error } catch {
        Issue.record("Unexpected error: \(String(describing: error))")
        return nil
    }
}
