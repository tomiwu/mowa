import MowaCore

/// Loads a value on the first call and keeps it for the next calls.
actor LoadOnce<Value: Sendable> {
    private let isReady: @Sendable () -> Bool
    private let availableBytes: @Sendable () -> UInt64
    private let budget: MemoryBudget
    private let load: @Sendable () async throws -> Value
    private var value: Value?

    init(
        isReady: @escaping @Sendable () -> Bool,
        availableBytes: @escaping @Sendable () -> UInt64 = { .max },
        budget: MemoryBudget = .modelLoad,
        load: @escaping @Sendable () async throws -> Value
    ) {
        self.isReady = isReady
        self.availableBytes = availableBytes
        self.budget = budget
        self.load = load
    }

    /// Returns the kept value. Throws `.modelNotInstalled` when the files are not there,
    /// `.notEnoughMemory` when the free memory is below the budget (the load does not run) and
    /// `.modelLoadFailed` when the load fails.
    func get() async throws(TranscriptionError) -> Value {
        if let value { return value }
        guard isReady() else { throw .modelNotInstalled }
        guard budget.allows(availableBytes: availableBytes()) else { throw .notEnoughMemory }
        let loaded = try await mapTranscriptionFailure(to: .modelLoadFailed, load)
        value = loaded
        return loaded
    }

    /// Drops the kept value. The next `get` loads it again.
    func reset() {
        value = nil
    }
}
