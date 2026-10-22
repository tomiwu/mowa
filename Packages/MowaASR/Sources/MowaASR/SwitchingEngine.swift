public import MowaCore

/// Sends each utterance to the engine of the model that the user selects now.
public struct SwitchingEngine: TranscriptionEngine {
    private let choice: @Sendable () -> ModelChoice
    private let engines: [ModelChoice: any TranscriptionEngine]
    private let log: PhaseLog

    public init(
        choice: @escaping @Sendable () -> ModelChoice,
        engines: [ModelChoice: any TranscriptionEngine],
        log: PhaseLog = .silent
    ) {
        self.choice = choice
        self.engines = engines
        self.log = log
    }

    public func transcribe(_ samples: [Float]) async throws(TranscriptionError) -> Transcript {
        let model = choice()
        guard let engine = engines[model] else { throw .modelNotInstalled }
        return try await log.around(.transcriptionStart, .transcriptionEnd, model: model) {
            () async throws(TranscriptionError) -> Transcript in
            try await engine.transcribe(samples)
        }
    }
}
