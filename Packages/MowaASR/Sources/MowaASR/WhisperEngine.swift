#if canImport(WhisperKit)
    import Foundation
    public import MowaCore
    import WhisperKit

    /// Transcribes on the device with Whisper large-v3 turbo through WhisperKit.
    ///
    /// Whisper detects the language of each utterance. The engine loads the model on the first
    /// call. It never uses the network: the model manager downloads the model before.
    public actor WhisperEngine: TranscriptionEngine {
        private let loader: LoadOnce<WhisperKit>

        public init(store: WhisperModelStore) {
            loader = LoadOnce(
                isReady: { store.isInstalled },
                load: {
                    try await WhisperKit(
                        WhisperKitConfig(
                            modelFolder: store.directory.path,
                            verbose: false,
                            load: true,
                            download: false
                        )
                    )
                }
            )
        }

        public func transcribe(_ samples: [Float]) async throws(TranscriptionError) -> Transcript {
            let kit = try await loader.get()
            let parts = try await mapTranscriptionFailure(to: .transcriptionFailed) {
                try await kit.transcribe(audioArray: samples, decodeOptions: Self.options)
                    .map(\.text)
            }
            return Transcript(text: Self.joinedText(of: parts))
        }

        static func joinedText(of parts: [String]) -> String {
            parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        private static let options = DecodingOptions(
            task: .transcribe,
            usePrefillPrompt: true,
            detectLanguage: true
        )
    }
#endif
