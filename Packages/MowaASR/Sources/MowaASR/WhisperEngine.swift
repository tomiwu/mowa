#if canImport(WhisperKit)
    import Foundation
    public import MowaCore
    import WhisperKit

    /// Transcribes on the device with Whisper large-v3 turbo through WhisperKit.
    ///
    /// Whisper detects the language of each utterance. The engine loads the model on the first
    /// call. It never uses the network: the model manager downloads the model before.
    public actor WhisperEngine: ReleasableEngine {
        private let loader: LoadOnce<WhisperRuntime>

        public init(store: WhisperModelStore, log: PhaseLog = .silent) {
            loader = LoadOnce(
                isReady: { store.isInstalled },
                availableBytes: MemoryBudget.systemAvailableBytes,
                load: {
                    try await log.around(.modelLoadStart, .modelLoadEnd, model: .whisper) {
                        try await WhisperRuntime.open(folder: store.directory.path)
                    }
                }
            )
        }

        public func release() async {
            await loader.reset()
        }

        public func transcribe(_ samples: [Float]) async throws(TranscriptionError) -> Transcript {
            let runtime = try await loader.get()
            let parts = try await mapTranscriptionFailure(to: .transcriptionFailed) {
                try await runtime.transcribe(samples)
            }
            return Transcript(text: Self.joinedText(of: parts))
        }

        static func joinedText(of parts: [String]) -> String {
            parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Keeps one WhisperKit model.
    ///
    /// WhisperKit is a class and does not conform to Sendable, so LoadOnce cannot store it.
    /// This actor creates the model and is the only type that calls it.
    private actor WhisperRuntime {
        // The kit is not Sendable. Only this actor calls it.
        nonisolated(unsafe) private let kit: WhisperKit

        private init(kit: sending WhisperKit) {
            self.kit = kit
        }

        static func open(folder: String) async throws -> WhisperRuntime {
            let kit = try await WhisperKit(Self.config(folder: folder))
            return WhisperRuntime(kit: kit)
        }

        func transcribe(_ samples: [Float]) async throws -> [String] {
            let results = try await kit.transcribe(
                audioArray: samples,
                decodeOptions: Self.options
            )
            return results.map(\.text)
        }

        private static func config(folder: String) -> WhisperKitConfig {
            WhisperKitConfig(
                modelFolder: folder,
                verbose: false,
                load: true,
                download: false
            )
        }

        private static let options = DecodingOptions(
            task: .transcribe,
            usePrefillPrompt: true,
            detectLanguage: true
        )
    }
#endif
