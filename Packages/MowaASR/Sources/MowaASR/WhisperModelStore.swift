#if canImport(WhisperKit)
    import Foundation
    public import MowaCore
    import WhisperKit

    /// Files of the Whisper model (Core ML) from Hugging Face.
    ///
    /// The variant depends on the device: a small device gets the base model.
    public struct WhisperModelStore: ModelStore {
        let variant: String
        public let sizeInBytes: Int64
        private let base = URL.applicationSupportDirectory.appending(path: "whisperkit")

        public init(variant: WhisperVariant = .forDevice(identifier: DeviceIdentifier.current)) {
            self.variant = variant.name
            sizeInBytes = variant.sizeInBytes
        }

        var directory: URL {
            base.appending(path: "models/argmaxinc/whisperkit-coreml/\(variant)")
        }

        public var isInstalled: Bool {
            FileManager.default.fileExists(
                atPath: directory.appending(path: "AudioEncoder.mlmodelc").path
            )
        }

        public func download() -> AsyncThrowingStream<Double, any Error> {
            let base = base
            let variant = variant
            return progressStream { report in
                _ = try await WhisperKit.download(
                    variant: variant,
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
