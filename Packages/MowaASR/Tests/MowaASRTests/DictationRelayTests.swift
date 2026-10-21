import Foundation
import MowaCore
import MowaShared
import Synchronization
import Testing

@testable import MowaASR

private struct FakeEngine: TranscriptionEngine {
    let outcome: Result<Transcript, TranscriptionError>

    func transcribe(_: [Float]) async throws(TranscriptionError) -> Transcript {
        try outcome.get()
    }
}

private final class CountingTransport: NotificationTransport {
    let posts = Mutex(0)

    func post(_: DarwinNotificationName) {
        posts.withLock { $0 += 1 }
    }

    func notifications(named _: DarwinNotificationName) -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}

private final class EntryLog: Sendable {
    private let items = Mutex<[HistoryEntry]>([])

    var all: [HistoryEntry] { items.withLock { $0 } }

    func add(_ entry: HistoryEntry) {
        items.withLock { $0.append(entry) }
    }
}

struct DictationRelayTests {
    private let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    private let transport = CountingTransport()
    private let id = UUID()

    private let entries = EntryLog()

    private func relay(
        _ outcome: Result<Transcript, TranscriptionError>,
        directory: URL? = nil
    ) throws -> DictationRelay {
        try FileManager.default.createDirectory(
            at: self.directory,
            withIntermediateDirectories: true
        )
        return DictationRelay(
            engine: FakeEngine(outcome: outcome),
            store: SharedStore(directory: directory ?? self.directory),
            notifier: DarwinNotifier(transport: transport),
            makeID: { [id] in id },
            now: { Date(timeIntervalSince1970: 5) },
            history: { [entries] in entries.add($0) }
        )
    }

    private var stored: DictationResult? {
        try? SharedStore(directory: directory).readResult()
    }

    @Test func correctsNamesFromWordList() async throws {
        let relay = try relay(.success(Transcript(text: "jade do wroclaw")))
        try SharedStore(directory: directory).writeWordList(["Wrocław"])
        await relay.handle(SpeechSegment(samples: [0.1]))
        #expect(stored?.text == "jade do Wrocław")
        #expect(entries.all.first?.text == "jade do Wrocław")
    }

    @Test func storesTextAndNotifiesKeyboard() async throws {
        let relay = try relay(.success(Transcript(text: "Dzień dobry")))
        await relay.handle(SpeechSegment(samples: [0.1]))
        #expect(
            stored
                == DictationResult(
                    id: id,
                    text: "Dzień dobry",
                    languageCode: "und",
                    createdAt: Date(timeIntervalSince1970: 5)
                )
        )
        #expect(transport.posts.withLock { $0 } == 1)
    }

    @Test func historyGetsTextLanguageDateAndDuration() async throws {
        let relay = try relay(.success(Transcript(text: "tak", languageCode: "pl")))
        await relay.handle(SpeechSegment(samples: [Float](repeating: 0, count: 8_000)))
        #expect(
            entries.all
                == [
                    HistoryEntry(
                        id: id,
                        date: Date(timeIntervalSince1970: 5),
                        text: "tak",
                        languageCode: "pl",
                        duration: 0.5
                    )
                ]
        )
    }

    @Test func emptyTextIsNotInHistory() async throws {
        let relay = try relay(.success(Transcript(text: "")))
        await relay.handle(SpeechSegment(samples: [0.1]))
        #expect(entries.all.isEmpty)
    }

    @Test func failedTranscriptionSendsNothing() async throws {
        let relay = try relay(.failure(.transcriptionFailed))
        await relay.handle(SpeechSegment(samples: [0.1]))
        #expect(stored == nil)
        #expect(transport.posts.withLock { $0 } == 0)
    }

    @Test func emptyTextSendsNothing() async throws {
        let relay = try relay(.success(Transcript(text: "")))
        await relay.handle(SpeechSegment(samples: [0.1]))
        #expect(transport.posts.withLock { $0 } == 0)
    }

    @Test func failedWriteSendsNothing() async throws {
        let missing = directory.appendingPathComponent("missing")
        let relay = try relay(.success(Transcript(text: "tak")), directory: missing)
        await relay.handle(SpeechSegment(samples: [0.1]))
        #expect(transport.posts.withLock { $0 } == 0)
    }
}

struct TranscriptionFailureTests {
    private struct Boom: Error {}

    @Test func passesTheValue() async throws {
        #expect(try await mapTranscriptionFailure(to: .modelLoadFailed) { 5 } == 5)
    }

    @Test func replacesTheError() async {
        await #expect(throws: TranscriptionError.modelLoadFailed) {
            try await mapTranscriptionFailure(to: .modelLoadFailed) { throw Boom() }
        }
    }
}
