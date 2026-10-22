#if canImport(FluidAudio)
    import FluidAudio
    public import MowaCore

    /// Transcribes on the device with Parakeet TDT 0.6B v3 through FluidAudio.
    ///
    /// The model has automatic language ID, so one engine serves Polish and English. The engine
    /// loads the model on the first call. It never uses the network: the model manager
    /// downloads the model before.
    public actor ParakeetEngine: TranscriptionEngine {
        private let loader: LoadOnce<AsrManager>

        public init(store: ParakeetModelStore, log: PhaseLog = .silent) {
            loader = LoadOnce(
                isReady: { store.isInstalled },
                load: {
                    try await log.around(.modelLoadStart, .modelLoadEnd, model: .parakeet) {
                        let models = try await AsrModels.load(from: store.directory, version: .v3)
                        let manager = AsrManager()
                        try await manager.loadModels(models)
                        return manager
                    }
                }
            )
        }

        public func transcribe(_ samples: [Float]) async throws(TranscriptionError) -> Transcript {
            let manager = try await loadedManager()
            let text = try await mapTranscriptionFailure(to: .transcriptionFailed) {
                try await Self.text(of: samples, using: manager)
            }
            return Transcript(text: text)
        }

        private static func text(of samples: [Float], using manager: AsrManager) async throws
            -> String
        {
            var state = TdtDecoderState.make(decoderLayers: await manager.decoderLayerCount)
            return try await manager.transcribe(samples, decoderState: &state).text
        }

        private func loadedManager() async throws(TranscriptionError) -> AsrManager {
            try await loader.get()
        }
    }
#endif
