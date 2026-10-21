#if canImport(FluidAudio)
    import FluidAudio
    import Foundation
    public import MowaCore

    /// Files of the Parakeet TDT 0.6B v3 model (Core ML, int8 encoder) from Hugging Face.
    ///
    /// The download is the only network use of the app.
    public struct ParakeetModelStore: ModelStore {
        /// About 595 MB for the int8 encoder variant (FluidAudio Models.md).
        public let sizeInBytes: Int64 = 595_000_000
        let directory = AsrModels.defaultCacheDirectory(for: .v3)

        public init() {}

        public var isInstalled: Bool {
            AsrModels.modelsExist(at: directory, version: .v3)
        }

        public func download() -> AsyncThrowingStream<Double, any Error> {
            let (stream, continuation) = AsyncThrowingStream<Double, any Error>.makeStream()
            let task = Task {
                do {
                    _ = try await AsrModels.download(version: .v3) {
                        continuation.yield($0.fractionCompleted)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
            return stream
        }

        public func delete() throws(ModelStoreError) {
            try Result { try FileManager.default.removeItem(at: directory) }
                .mapError { _ in ModelStoreError.deleteFailed }
                .get()
        }
    }
#endif
