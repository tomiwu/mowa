/// Errors that the shared store reports.
public enum SharedStoreError: Error, Equatable, Sendable {
    case containerUnavailable
    case writeFailed
    case readFailed
}
