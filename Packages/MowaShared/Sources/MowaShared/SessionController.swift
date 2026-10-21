public import Foundation

/// Runs the recording session of the app.
///
/// The session starts from the URL of the keyboard. It ends after the idle timeout, or when the
/// keyboard asks to stop. The recorder runs only while the session is active.
@MainActor
public final class SessionController {
    private let store: SharedStore
    private let notifier: DarwinNotifier
    private let recorder: any AudioRecorder
    private let sleep: @Sendable (Duration) async throws -> Void
    private var idleTask: Task<Void, Never>?
    public private(set) var status = SessionStatus.noSession

    public init(
        store: SharedStore,
        notifier: DarwinNotifier,
        recorder: any AudioRecorder,
        sleep: @escaping @Sendable (Duration) async throws -> Void
    ) {
        self.store = store
        self.notifier = notifier
        self.recorder = recorder
        self.sleep = sleep
    }

    /// Starts a session when the URL is the start URL of the keyboard.
    public func handle(url: URL) {
        guard url.absoluteString == MowaShared.startURLString else { return }
        start()
    }

    /// Starts the recorder, or restarts the idle timer when a session is active.
    public func start() {
        if status == .noSession {
            guard (try? recorder.start()) != nil else { return }
            publish(.recording)
        }
        noteActivity()
    }

    /// Restarts the idle timer. Call it for each dictation.
    public func noteActivity() {
        idleTask?.cancel()
        let timeout = ((try? store.readSettings()) ?? .standard).idleTimeout
        idleTask = Task { [sleep] in
            guard (try? await sleep(timeout)) != nil else { return }
            end()
        }
    }

    /// Stops the recorder and the idle timer.
    public func end() {
        idleTask?.cancel()
        recorder.stop()
        publish(.noSession)
    }

    /// Ends the session for each stop request of the keyboard.
    public func observeStopRequests() async {
        for await _ in notifier.stopRequested() {
            end()
        }
    }

    private func publish(_ newStatus: SessionStatus) {
        status = newStatus
        try? store.writeSessionStatus(newStatus)
        notifier.postSessionChanged()
    }
}
