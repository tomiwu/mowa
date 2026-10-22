#if canImport(os)
    import os
#endif

/// Writes one log line for each phase of a dictation. Each line has the model choice and the
/// free memory of the process, so a device log shows where the memory goes.
public struct PhaseLog: Sendable {
    /// The phases that the log records, in the order of a dictation.
    public enum Phase: String, CaseIterable, Sendable {
        case modelLoadStart = "model-load-start"
        case modelLoadEnd = "model-load-end"
        case recordStart = "record-start"
        case recordStop = "record-stop"
        case transcriptionStart = "transcription-start"
        case transcriptionEnd = "transcription-end"
    }

    /// A log that writes nothing.
    public static let silent = PhaseLog(write: { _ in }, availableBytes: { 0 })

    private let write: @Sendable (String) -> Void
    private let availableBytes: @Sendable () -> UInt64

    public init(
        write: @escaping @Sendable (String) -> Void,
        availableBytes: @escaping @Sendable () -> UInt64
    ) {
        self.write = write
        self.availableBytes = availableBytes
    }

    /// The text of one log line.
    public static func message(phase: Phase, model: ModelChoice, availableBytes: UInt64) -> String {
        "\(phase.rawValue) model=\(model.rawValue) available-bytes=\(availableBytes)"
    }

    public func record(_ phase: Phase, model: ModelChoice) {
        write(Self.message(phase: phase, model: model, availableBytes: availableBytes()))
    }

    /// Writes the start line, runs the operation, and writes the end line only if it succeeds.
    public func around<Value, Failure: Error>(
        _ start: Phase,
        _ end: Phase,
        model: ModelChoice,
        operation: () async throws(Failure) -> Value
    ) async throws(Failure) -> Value {
        record(start, model: model)
        let value = try await operation()
        record(end, model: model)
        return value
    }
}

#if canImport(os)
    extension PhaseLog {
        /// A log that writes to the unified log and reads `os_proc_available_memory`.
        public static func system() -> PhaseLog {
            let logger = Logger(subsystem: "com.tomiwu.mowa", category: "dictation")
            return PhaseLog(
                write: { logger.notice("\($0, privacy: .public)") },
                availableBytes: { UInt64(os_proc_available_memory()) }
            )
        }
    }
#endif
