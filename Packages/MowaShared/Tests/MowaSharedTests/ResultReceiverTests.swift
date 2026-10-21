import Foundation
import Testing

@testable import MowaShared

@MainActor
struct ResultReceiverTests {
    private let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    private let host = FakeHost()

    private func makeStore() throws -> SharedStore {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return SharedStore(directory: directory)
    }

    private func result(_ text: String) -> DictationResult {
        DictationResult(
            id: UUID(),
            text: text,
            languageCode: "pl",
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    @Test func deliverInsertsAndClearsResult() throws {
        let store = try makeStore()
        try store.writeResult(result("Dzień dobry"))
        ResultReceiver(store: store).deliver(to: host)
        #expect(host.calls == ["insert:Dzień dobry"])
        #expect(try store.readResult() == nil)
    }

    @Test func deliverDoesNothingWithoutResult() throws {
        ResultReceiver(store: try makeStore()).deliver(to: host)
        #expect(host.calls.isEmpty)
    }

    @Test func deliverDoesNothingWithoutStore() {
        ResultReceiver(store: nil).deliver(to: host)
        #expect(host.calls.isEmpty)
    }

    @Test func observeDeliversForEachNotification() async throws {
        let store = try makeStore()
        try store.writeResult(result("hello"))
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        continuation.yield()
        continuation.finish()
        await ResultReceiver(store: store).observe(changes: stream, host: host)
        #expect(host.calls == ["insert:hello"])
    }
}
