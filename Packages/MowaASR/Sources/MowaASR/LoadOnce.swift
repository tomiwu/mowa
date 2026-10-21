import MowaCore

/// Loads a value on the first call and keeps it for the next calls.
actor LoadOnce<Value: Sendable> {
    private let isReady: @Sendable () -> Bool
    private let load: @Sendable () async throws -> Value
    private var value: Value?

    init(
        isReady: @escaping @Sendable () -> Bool,
        load: @escaping @Sendable () async throws -> Value
    ) {
        self.isReady = isReady
        self.load = load
    }

    /// Returns the kept value. Throws `.modelNotInstalled` when the files are not there and
    /// `.modelLoadFailed` when the load fails.
    func get() async throws(TranscriptionError) -> Value {
        if let value { return value }
        guard isReady() else { throw .modelNotInstalled }
        let loaded = try await mapTranscriptionFailure(to: .modelLoadFailed, load)
        value = loaded
        return loaded
    }
}
