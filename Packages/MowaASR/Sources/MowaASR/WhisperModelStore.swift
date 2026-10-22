#if canImport(WhisperKit)
    import Foundation
    public import MowaCore
    import WhisperKit

    /// Files of the Whisper large-v3 turbo model (Core ML, 626 MB variant) from Hugging Face.
    public struct WhisperModelStore: ModelStore {
        static let variant = "openai_whisper-large-v3-v20240930_626MB"

        /// About 626 MB, as the name of the variant says.
        public let sizeInBytes: Int64 = 626_000_000
        private let base = URL.applicationSupportDirectory.appending(path: "whisperkit")

        public init() {}

        var directory: URL {
            base.appending(path: "models/argmaxinc/whisperkit-coreml/\(Self.variant)")
        }

        public var isInstalled: Bool {
            FileManager.default.fileExists(
                atPath: directory.appending(path: "AudioEncoder.mlmodelc").path
            )
        }

        public func download() -> AsyncThrowingStream<Double, any Error> {
            let base = base
            return progressStream { report in
                _ = try await WhisperKit.download(
                    variant: Self.variant,
                    downloadBase: base,
                    progressCallback: { report($0.fractionCompleted) }
                )
            }
        }

        public func delete() throws(ModelStoreError) {
            try Result { try FileManager.default.removeItem(at: directory) }
                .mapError { _ in ModelStoreError.deleteFailed }
                .get()
        }
    }
#endif
