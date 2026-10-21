#if canImport(FluidAudio)
    import FluidAudio

    /// Speech detector with the Silero VAD model of FluidAudio (Core ML, MIT licence).
    public actor SileroSpeechDetector: SpeechActivityDetector {
        private let manager: VadManager
        private var state = VadStreamState.initial()

        /// Loads the model. The first call downloads it.
        public init() async throws(SpeechPipelineError) {
            manager = try await mapFailure(to: .detectorUnavailable) { try await VadManager() }
        }

        /// Starts a new recording. The model forgets the audio of the last one.
        public func reset() {
            state = VadStreamState.initial()
        }

        public func probability(of chunk: [Float]) async throws(SpeechPipelineError) -> Float {
            let result = try await mapFailure(to: .detectionFailed) {
                try await manager.processStreamingChunk(chunk, state: state)
            }
            state = result.state
            return result.probability
        }
    }
#endif
