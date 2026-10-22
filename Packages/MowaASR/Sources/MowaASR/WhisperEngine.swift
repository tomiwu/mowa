#if canImport(WhisperKit)
    import Foundation
    public import MowaCore
    import WhisperKit

    /// Transcribes on the device with Whisper large-v3 turbo through WhisperKit.
    ///
    /// Whisper detects the language of each utterance. The engine loads the model on the first
    /// call. It never uses the network: the model manager downloads the model before.
    public actor WhisperEngine: TranscriptionEngine {
        private let store: WhisperModelStore
        private var kit: WhisperKit?

        public init(store: WhisperModelStore) {
            self.store = store
        }

        public func transcribe(_ samples: [Float]) async throws(TranscriptionError) -> Transcript {
            let kit = try await loadedKit()
            let results = try await mapTranscriptionFailure(to: .transcriptionFailed) {
                try await kit.transcribe(audioArray: samples, decodeOptions: Self.options)
            }
            return Transcript(text: Self.joinedText(of: results.map(\.text)))
        }

        static func joinedText(of parts: [String]) -> String {
            parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        private static let options = DecodingOptions(
            task: .transcribe,
            usePrefillPrompt: true,
            detectLanguage: true
        )

        private func loadedKit() async throws(TranscriptionError) -> WhisperKit {
            if let kit { return kit }
            guard store.isInstalled else { throw .modelNotInstalled }
            let config = WhisperKitConfig(
                modelFolder: store.directory.path,
                verbose: false,
                load: true,
                download: false
            )
            let loaded = try await mapTranscriptionFailure(to: .modelLoadFailed) {
                try await WhisperKit(config)
            }
            kit = loaded
            return loaded
        }
    }
#endif
