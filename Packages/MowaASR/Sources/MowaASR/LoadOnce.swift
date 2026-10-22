import MowaCore

/// Loads a value on the first call and keeps it for the next calls.
actor LoadOnce<Value: Sendable> {
    private let isReady: @Sendable () -> Bool
    private let availableBytes: @Sendable () -> UInt64
    private let budget: MemoryBudget
    private let load: @Sendable () async throws -> Value
    private var value: Value?
    private var inFlight: Task<Value, any Error>?
    private var generation = 0

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
        try checkCanLoad()
        let (task, id) = currentLoad()
        do {
            let loaded = try await mapTranscriptionFailure(to: .modelLoadFailed) {
                try await task.value
            }
            finish(id, loaded)
            return loaded
        } catch {
            finish(id, nil)
            throw error
        }
    }

    /// Drops the kept value. The next `get` loads it again.
    func reset() {
        value = nil
        inFlight = nil
        generation += 1
    }

    private func checkCanLoad() throws(TranscriptionError) {
        guard isReady() else { throw .modelNotInstalled }
        guard budget.allows(availableBytes: availableBytes()) else { throw .notEnoughMemory }
    }

    private func currentLoad() -> (Task<Value, any Error>, Int) {
        if let inFlight { return (inFlight, generation) }
        let task = Task { try await load() }
        inFlight = task
        return (task, generation)
    }

    private func finish(_ id: Int, _ loaded: Value?) {
        guard id == generation, inFlight != nil else { return }
        inFlight = nil
        value = loaded
    }
}
