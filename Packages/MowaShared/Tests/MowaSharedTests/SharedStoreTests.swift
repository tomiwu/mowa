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

    @Test func corruptFileThrowsReadFailed() throws {
        let (store, directory) = try makeStore()
        try Data("not json".utf8).write(to: directory.appendingPathComponent("result.json"))
        #expect(throws: SharedStoreError.readFailed) { try store.readResult() }
    }

    @Test func missingDirectoryThrowsWriteFailed() {
        let store = SharedStore(directory: URL(fileURLWithPath: "/nonexistent/mowa"))
        #expect(throws: SharedStoreError.writeFailed) { try store.writeWordList([]) }
    }
}
