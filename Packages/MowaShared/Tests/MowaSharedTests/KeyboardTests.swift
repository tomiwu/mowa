import Testing

@testable import MowaShared

@MainActor
final class FakeHost: KeyboardHost {
    private(set) var calls: [String] = []

    func insertText(_ text: String) { calls.append("insert:\(text)") }
    func deleteBackward() { calls.append("delete") }
    func advanceToNextInputMode() { calls.append("next") }
    func openStartURL() { calls.append("open") }
    func requestStop() { calls.append("stop") }
}

@MainActor
struct KeyboardTests {
    private func calls(of action: KeyAction) -> [String] {
        let host = FakeHost()
        action.perform(on: host)
        return host.calls
    }

    @Test func spaceInsertsSpace() {
        #expect(calls(of: .space) == ["insert: "])
    }

    @Test func returnInsertsNewline() {
        #expect(calls(of: .returnKey) == ["insert:\n"])
    }

    @Test func deleteDeletesBackward() {
        #expect(calls(of: .delete) == ["delete"])
    }

    @Test func globeAdvancesInputMode() {
        #expect(calls(of: .nextKeyboard) == ["next"])
    }

    @Test func insertInsertsText() {
        #expect(calls(of: .insert("Wrocław")) == ["insert:Wrocław"])
    }

    @Test func micOpensAppWithoutSession() {
        #expect(calls(of: .mic(status: .noSession)) == ["open"])
    }

    @Test(arguments: [SessionStatus.recording, .processing])
    func micStopsWithSession(status: SessionStatus) {
        #expect(calls(of: .mic(status: status)) == ["stop"])
    }

    @Test func statusLabelsAreForTheUser() {
        let labels = [SessionStatus.recording, .processing, .noSession, .lowMemory].map(\.label)
        #expect(labels == ["recording", "processing", "no session", "not enough memory"])
    }

    @Test func startURLUsesScheme() {
        #expect(MowaShared.startURLString == "mowa://start")
    }

    @Test func modelStartsWithoutSession() {
        let model = KeyboardModel(readStatus: { .recording })
        #expect(model.status == .noSession)
        #expect(calls(of: model.micAction) == ["open"])
    }

    @Test func refreshReadsStatus() {
        let model = KeyboardModel(readStatus: { .processing })
        model.refresh()
        #expect(model.status == .processing)
        #expect(calls(of: model.micAction) == ["stop"])
    }

    @Test func observeUpdatesAfterEachChange() async {
        let model = KeyboardModel(readStatus: { .recording })
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        continuation.yield()
        continuation.finish()
        await model.observe(changes: stream)
        #expect(model.status == .recording)
    }

    @Test func sessionAndStopNotificationsReachReceiver() async {
        let notifier = DarwinNotifier(transport: FakeTransport())
        let changed = notifier.sessionChanged()
        let stop = notifier.stopRequested()
        notifier.postSessionChanged()
        notifier.postStopRequested()
        var changedIterator = changed.makeAsyncIterator()
        var stopIterator = stop.makeAsyncIterator()
        let first: Void? = await changedIterator.next()
        let second: Void? = await stopIterator.next()
        #expect(first != nil)
        #expect(second != nil)
    }
}
