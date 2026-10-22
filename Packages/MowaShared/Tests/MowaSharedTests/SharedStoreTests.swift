import Foundation
import Testing

@testable import MowaShared

struct SharedStoreTests {
    private func makeStore() throws -> (SharedStore, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return (SharedStore(directory: directory), directory)
    }

    private let sample = DictationResult(
        id: UUID(),
        text: "Cześć, świecie",
        languageCode: "pl",
        createdAt: Date(timeIntervalSince1970: 1_000)
    )

    @Test func storeUsesFallbackWithoutContainer() throws {
        let (_, directory) = try makeStore()
        let store = SharedStore(container: nil, fallback: directory)
        try store.writeSessionStatus(.recording)
        #expect(try SharedStore(directory: directory).readSessionStatus() == .recording)
    }

    @Test func resultRoundTrips() throws {
        let (store, _) = try makeStore()
        try store.writeResult(sample)
        #expect(try store.readResult() == sample)
    }

    @Test func resultIsNilWhenMissing() throws {
        let (store, _) = try makeStore()
        #expect(try store.readResult() == nil)
    }

    @Test func clearResultRemovesResult() throws {
        let (store, _) = try makeStore()
        try store.writeResult(sample)
        store.clearResult()
        #expect(try store.readResult() == nil)
    }

    @Test func clearResultIgnoresMissingFile() throws {
        let (store, _) = try makeStore()
        store.clearResult()
    }

    @Test func wordListRoundTrips() throws {
        let (store, _) = try makeStore()
        try store.writeWordList(["Wrocław", "Kubernetes"])
        #expect(try store.readWordList() == ["Wrocław", "Kubernetes"])
    }

    @Test func wordListIsEmptyWhenMissing() throws {
        let (store, _) = try makeStore()
        #expect(try store.readWordList().isEmpty)
    }

    @Test func settingsRoundTrip() throws {
        let (store, _) = try makeStore()
        let settings = SharedSettings(languageCode: "pl", cleanUpEnabled: true)
        try store.writeSettings(settings)
        #expect(try store.readSettings() == settings)
    }

    @Test func settingsAreStandardWhenMissing() throws {
        let (store, _) = try makeStore()
        #expect(try store.readSettings() == .standard)
    }

    @Test func cleanUpIsOffByDefault() throws {
        let (store, _) = try makeStore()
        #expect(!store.isCleanUpEnabled)
    }

    @Test func cleanUpToggleIsSavedAndKeepsOtherSettings() throws {
        let (store, _) = try makeStore()
        try store.writeSettings(SharedSettings(languageCode: "pl", cleanUpEnabled: false))
        try store.setCleanUp(enabled: true)
        #expect(store.isCleanUpEnabled)
        #expect(try store.readSettings().languageCode == "pl")
    }

    @Test func sessionStatusRoundTrips() throws {
        let (store, _) = try makeStore()
        try store.writeSessionStatus(.recording)
        #expect(try store.readSessionStatus() == .recording)
    }

    @Test func sessionStatusIsNoSessionWhenMissing() throws {
        let (store, _) = try makeStore()
        #expect(try store.readSessionStatus() == .noSession)
    }

    @Test func corruptFileThrowsReadFailed() throws {
        let (store, directory) = try makeStore()
        try Data("not json".utf8).write(to: directory.appendingPathComponent("result.json"))
        #expect(throws: SharedStoreError.readFailed) { try store.readResult() }
    }

    @Test func missingDirectoryThrowsWriteFailed() {
        let store = SharedStore(directory: URL(fileURLWithPath: "/nonexistent/mowa"))
        #expect(throws: SharedStoreError.writeFailed) { try store.writeWordList([]) }
    }

    @Test func missingContainerThrowsContainerUnavailable() {
        #expect(throws: SharedStoreError.containerUnavailable) {
            try SharedStore(container: nil)
        }
    }

    @Test func containerOpensStore() throws {
        let (_, directory) = try makeStore()
        let store = try SharedStore(container: directory)
        try store.writeWordList(["a"])
        #expect(try store.readWordList() == ["a"])
    }
}
