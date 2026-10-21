import Testing

@testable import MowaCore

private final class FakeModelStore: ModelStore, @unchecked Sendable {
    // The tests use the store from the main actor only.
    var installed: Bool
    var fractions: [Double] = []
    var downloadError: (any Error)?
    var deleteError: ModelStoreError?
    var downloadCount = 0
    let sizeInBytes: Int64 = 595_000_000

    init(installed: Bool = false) {
        self.installed = installed
    }

    var isInstalled: Bool { installed }

    func download() -> AsyncThrowingStream<Double, any Error> {
        downloadCount += 1
        let (stream, continuation) = AsyncThrowingStream<Double, any Error>.makeStream()
        fractions.forEach { continuation.yield($0) }
        continuation.finish(throwing: downloadError)
        return stream
    }

    func delete() throws(ModelStoreError) {
        if let deleteError { throw deleteError }
        installed = false
    }
}

private struct DownloadFailure: Error {}

@MainActor
struct ModelManagerTests {
    @Test func startsNotDownloadedWhenModelIsMissing() {
        #expect(ModelManager(store: FakeModelStore()).state == .notDownloaded)
    }

    @Test func startsReadyWhenModelIsInstalled() {
        #expect(ModelManager(store: FakeModelStore(installed: true)).state == .ready)
    }

    @Test func showsSizeBeforeDownload() {
        #expect(ModelManager(store: FakeModelStore()).sizeText == "595 MB")
    }

    @Test func downloadEndsReady() async {
        let store = FakeModelStore()
        store.fractions = [0.5, 1]
        let manager = ModelManager(store: store)
        await manager.download()
        #expect(manager.state == .ready)
    }

    @Test func failedDownloadGivesFailedState() async {
        let store = FakeModelStore()
        store.downloadError = DownloadFailure()
        let manager = ModelManager(store: store)
        await manager.download()
        #expect(manager.state == .failed)
    }

    @Test func downloadRetriesAfterFailure() async {
        let store = FakeModelStore()
        store.downloadError = DownloadFailure()
        let manager = ModelManager(store: store)
        await manager.download()
        store.downloadError = nil
        await manager.download()
        #expect(manager.state == .ready)
    }

    @Test func downloadDoesNothingWhenReady() async {
        let store = FakeModelStore(installed: true)
        await ModelManager(store: store).download()
        #expect(store.downloadCount == 0)
    }

    @Test func deleteGivesNotDownloaded() {
        let manager = ModelManager(store: FakeModelStore(installed: true))
        manager.delete()
        #expect(manager.state == .notDownloaded)
    }

    @Test func failedDeleteGivesFailedState() {
        let store = FakeModelStore(installed: true)
        store.deleteError = .deleteFailed
        let manager = ModelManager(store: store)
        manager.delete()
        #expect(manager.state == .failed)
    }
}

struct ByteSizeTextTests {
    @Test(arguments: [
        (Int64(595_000_000), "595 MB"), (Int64(595_400_000), "595 MB"),
        (Int64(595_600_000), "596 MB"), (Int64(0), "0 MB"),
    ])
    func roundsToMegabytes(bytes: Int64, text: String) {
        #expect(ByteSizeText.text(for: bytes) == text)
    }
}

struct TranscriptTests {
    @Test func languageIsUndeterminedByDefault() {
        #expect(Transcript(text: "tak").languageCode == "und")
    }
}

struct ModelStateTests {
    @Test func fractionFollowsState() {
        #expect(ModelState.downloading(fraction: 0.4).fraction == 0.4)
        #expect(ModelState.ready.fraction == 1)
        #expect(ModelState.notDownloaded.fraction == 0)
        #expect(ModelState.failed.fraction == 0)
    }

    @Test func labelsTellTheState() {
        #expect(ModelState.notDownloaded.label == "Not downloaded")
        #expect(ModelState.downloading(fraction: 0.425).label == "Downloading 42 %")
        #expect(ModelState.ready.label == "Ready")
        #expect(ModelState.failed.label == "Failed")
    }

    @Test func buttonsFollowState() {
        #expect(ModelState.notDownloaded.canDownload && !ModelState.notDownloaded.canDelete)
        #expect(ModelState.failed.canDownload && ModelState.failed.canDelete)
        #expect(!ModelState.ready.canDownload && ModelState.ready.canDelete)
        #expect(!ModelState.downloading(fraction: 0).canDownload)
        #expect(!ModelState.downloading(fraction: 0).canDelete)
    }
}
