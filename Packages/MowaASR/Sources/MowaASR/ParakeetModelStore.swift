#if canImport(FluidAudio)
    import FluidAudio
    import Foundation
    public import MowaCore

    /// Files of the Parakeet Redux model (Core ML, 220 MB, same languages as v3) from Hugging Face.
    ///
    /// The download is the only network use of the app.
    public struct ParakeetModelStore: ModelStore {
        /// The measured size of the Redux files: 220.5 MB.
        public let sizeInBytes = ParakeetModelChoice.standard.sizeInBytes
        let directory = AsrModels.defaultCacheDirectory(for: .redux)

        public init() {}

        public var isInstalled: Bool {
            AsrModels.modelsExist(at: directory, version: .redux)
        }

        public func download() -> AsyncThrowingStream<Double, any Error> {
            progressStream { report in
                _ = try await AsrModels.download(version: .redux) { report($0.fractionCompleted) }
            }
        }

        public func delete() throws(ModelStoreError) {
            try Result { try FileManager.default.removeItem(at: directory) }
                .mapError { _ in ModelStoreError.deleteFailed }
                .get()
        }
    }
#endif
