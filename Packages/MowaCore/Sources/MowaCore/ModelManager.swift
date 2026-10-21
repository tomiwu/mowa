public import Observation

/// Downloads, shows and deletes the ASR model.
@MainActor
@Observable
public final class ModelManager {
    public private(set) var state: ModelState
    @ObservationIgnored private let store: any ModelStore

    public init(store: any ModelStore) {
        self.store = store
        state = store.isInstalled ? .ready : .notDownloaded
    }

    /// Size of the download, for the user to read before the download starts.
    public var sizeText: String {
        ByteSizeText.text(for: store.sizeInBytes)
    }

    /// Downloads the model. It does nothing when a download runs or the model is ready.
    public func download() async {
        guard state.canDownload else { return }
        state = .downloading(fraction: 0)
        state = await finish(store.download())
    }

    /// Deletes the files of the model.
    public func delete() {
        state = (try? store.delete()) == nil ? .failed : .notDownloaded
    }

    private func finish(_ progress: AsyncThrowingStream<Double, any Error>) async -> ModelState {
        do {
            for try await fraction in progress {
                state = .downloading(fraction: fraction)
            }
            return .ready
        } catch {
            return .failed
        }
    }
}
