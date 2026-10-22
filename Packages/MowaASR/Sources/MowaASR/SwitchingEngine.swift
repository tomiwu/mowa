public import MowaCore

/// Sends each utterance to the engine of the model that the user selects now.
public struct SwitchingEngine: TranscriptionEngine {
    private let choice: @Sendable () -> ModelChoice
    private let engines: [ModelChoice: any TranscriptionEngine]

    public init(
        choice: @escaping @Sendable () -> ModelChoice,
        engines: [ModelChoice: any TranscriptionEngine]
    ) {
        self.choice = choice
        self.engines = engines
    }

    public func transcribe(_ samples: [Float]) async throws(TranscriptionError) -> Transcript {
        guard let engine = engines[choice()] else { throw .modelNotInstalled }
        return try await engine.transcribe(samples)
    }
}
