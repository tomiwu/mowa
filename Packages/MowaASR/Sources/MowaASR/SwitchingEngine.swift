public import MowaCore

/// An engine that can free its model memory.
public protocol ReleasableEngine: TranscriptionEngine {
    /// Frees the loaded model. The next `transcribe` call loads it again.
    func release() async
}

/// Sends each utterance to the engine of the model that the user selects now.
///
/// The actor keeps only one engine. When the choice changes, it releases the old engine
/// before it creates the new engine, so two models are never in memory together.
public actor SwitchingEngine: TranscriptionEngine {
    private let choice: @Sendable () -> ModelChoice
    private let makers: [ModelChoice: @Sendable () -> any ReleasableEngine]
    private let log: PhaseLog
    private var current: (model: ModelChoice, engine: any ReleasableEngine)?

    public init(
        choice: @escaping @Sendable () -> ModelChoice,
        makers: [ModelChoice: @Sendable () -> any ReleasableEngine],
        log: PhaseLog = .silent
    ) {
        self.choice = choice
        self.makers = makers
        self.log = log
    }

    public func transcribe(_ samples: [Float]) async throws(TranscriptionError) -> Transcript {
        let model = choice()
        let engine = try await engine(for: model)
        return try await log.around(.transcriptionStart, .transcriptionEnd, model: model) {
            () async throws(TranscriptionError) -> Transcript in
            try await engine.transcribe(samples)
        }
    }

    private func engine(for model: ModelChoice) async throws(TranscriptionError)
        -> any ReleasableEngine
    {
        if let current, current.model == model { return current.engine }
        guard let make = makers[model] else { throw .modelNotInstalled }
        let old = current
        current = nil
        await old?.engine.release()
        let engine = make()
        current = (model, engine)
        return engine
    }
}
