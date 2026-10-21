import Foundation
import Synchronization
import Testing

@testable import MowaShared

private final class NamedTransport: NotificationTransport {
    private let observers = Mutex<[DarwinNotificationName: [AsyncStream<Void>.Continuation]]>([:])

    func post(_ name: DarwinNotificationName) {
        observers.withLock { $0[name, default: []].forEach { $0.yield() } }
    }

    func notifications(named name: DarwinNotificationName) -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        observers.withLock { $0[name, default: []].append(continuation) }
        return stream
    }
}

private final class FakeRecorder: AudioRecorder {
    struct Counts {
        var starts = 0
        var stops = 0
    }

    private let counts = Mutex(Counts())
    let failure: AudioRecorderError?

    init(failure: AudioRecorderError? = nil) {
        self.failure = failure
    }

    var starts: Int { counts.withLock { $0.starts } }
    var stops: Int { counts.withLock { $0.stops } }

    func start() throws(AudioRecorderError) {
        if let failure { throw failure }
        counts.withLock { $0.starts += 1 }
    }

    func stop() {
        counts.withLock { $0.stops += 1 }
    }
}

/// Sleep function that waits until the test calls `fire`.
private final class ManualClock: Sendable {
    private let pending = Mutex<[(Duration, CheckedContinuation<Void, any Error>)]>([])
    private let requested = Mutex<[Duration]>([])

    var durations: [Duration] { requested.withLock { $0 } }

    func sleep(_ duration: Duration) async throws {
        requested.withLock { $0.append(duration) }
        try await withCheckedThrowingContinuation { continuation in
            pending.withLock { $0.append((duration, continuation)) }
        }
        try Task.checkCancellation()
    }

    func fire() {
        let waiting = pending.withLock { items in
            defer { items = [] }
            return items
        }
        waiting.forEach { $0.1.resume() }
    }
}

@MainActor
struct SessionControllerTests {
    private let store: SharedStore
    private let recorder: FakeRecorder
    private let clock = ManualClock()
    private let controller: SessionController

    init(failure: AudioRecorderError? = nil) throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = SharedStore(directory: directory)
        recorder = FakeRecorder(failure: failure)
        let clock = clock
        controller = SessionController(
            store: store,
            notifier: DarwinNotifier(transport: NamedTransport()),
            recorder: recorder,
            sleep: { try await clock.sleep($0) }
        )
    }

    private func settle() async {
        for _ in 0..<20 { await Task.yield() }
    }

    @Test func noRecordingBeforeStart() throws {
        #expect(recorder.starts == 0)
        #expect(controller.status == .noSession)
        #expect(try store.readSessionStatus() == .noSession)
    }

    @Test func startURLStartsRecording() throws {
        controller.handle(url: try #require(URL(string: MowaShared.startURLString)))
        #expect(recorder.starts == 1)
        #expect(try store.readSessionStatus() == .recording)
    }

    @Test func otherURLIsIgnored() throws {
        controller.handle(url: try #require(URL(string: "mowa://other")))
        #expect(recorder.starts == 0)
        #expect(controller.status == .noSession)
    }

    @Test func secondStartKeepsOneRecording() {
        controller.start()
        controller.start()
        #expect(recorder.starts == 1)
    }

    @Test func recorderFailureLeavesNoSession() throws {
        let failing = try SessionControllerTests(failure: .permissionDenied)
        failing.controller.start()
        #expect(failing.controller.status == .noSession)
        #expect(try failing.store.readSessionStatus() == .noSession)
    }

    @Test func idleTimeoutDefaultsToFiveMinutes() async {
        controller.start()
        await settle()
        #expect(clock.durations == [.seconds(300)])
    }

    @Test func idleTimeoutFollowsSetting() async throws {
        try store.writeSettings(
            SharedSettings(languageCode: "pl", cleanUpEnabled: false, idleTimeoutMinutes: 2)
        )
        controller.start()
        await settle()
        #expect(clock.durations == [.seconds(120)])
    }

    @Test func timeoutEndsSession() async throws {
        controller.start()
        await settle()
        clock.fire()
        await settle()
        #expect(recorder.stops == 1)
        #expect(controller.status == .noSession)
        #expect(try store.readSessionStatus() == .noSession)
    }

    @Test func activityRestartsTimer() async {
        controller.start()
        await settle()
        controller.noteActivity()
        await settle()
        #expect(clock.durations.count == 2)
    }

    @Test func endCancelsTimer() async {
        controller.start()
        await settle()
        controller.end()
        clock.fire()
        await settle()
        #expect(recorder.stops == 1)
    }

    @Test func stopRequestEndsSession() async throws {
        let transport = NamedTransport()
        let notifier = DarwinNotifier(transport: transport)
        let clock = clock
        let observed = SessionController(
            store: store,
            notifier: notifier,
            recorder: recorder,
            sleep: { try await clock.sleep($0) }
        )
        observed.start()
        let observing = Task { await observed.observeStopRequests() }
        await settle()
        notifier.postStopRequested()
        await settle()
        observing.cancel()
        #expect(observed.status == .noSession)
        #expect(recorder.stops == 1)
    }
}

struct SharedSettingsTests {
    @Test func defaultIdleTimeoutIsFiveMinutes() {
        #expect(SharedSettings.standard.idleTimeout == .seconds(300))
    }

    @Test func idleTimeoutHasOneMinuteMinimum() {
        let settings = SharedSettings(
            languageCode: "pl",
            cleanUpEnabled: false,
            idleTimeoutMinutes: 0
        )
        #expect(settings.idleTimeout == .seconds(60))
    }

    @Test func oldSettingsWithoutTimeoutDecode() throws {
        let json = Data(#"{"languageCode":"pl","cleanUpEnabled":true}"#.utf8)
        let settings = try JSONDecoder().decode(SharedSettings.self, from: json)
        #expect(settings.idleTimeoutMinutes == 5)
    }
}
