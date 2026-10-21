/// Names of the Darwin notifications that the app and the keyboard send.
public enum DarwinNotificationName: String, Sendable {
    case resultReady = "group.com.tomiwu.mowa.result-ready"
    case sessionChanged = "group.com.tomiwu.mowa.session-changed"
    case stopRequested = "group.com.tomiwu.mowa.stop-requested"
}

/// Low-level channel for Darwin notifications. Tests use a fake.
public protocol NotificationTransport: Sendable {
    func post(_: DarwinNotificationName)
    func notifications(named _: DarwinNotificationName) -> AsyncStream<Void>
}

/// Sends and receives the notifications of the dictation flow.
public struct DarwinNotifier: Sendable {
    private let transport: any NotificationTransport

    public init(transport: any NotificationTransport) {
        self.transport = transport
    }

    /// The app calls this after it writes a result to the store.
    public func postResultReady() {
        transport.post(.resultReady)
    }

    /// The keyboard iterates this stream and reads the store for each element.
    public func resultReady() -> AsyncStream<Void> {
        transport.notifications(named: .resultReady)
    }

    /// The app calls this after it writes a new session status to the store.
    public func postSessionChanged() {
        transport.post(.sessionChanged)
    }

    /// The keyboard iterates this stream and reads the status for each element.
    public func sessionChanged() -> AsyncStream<Void> {
        transport.notifications(named: .sessionChanged)
    }

    /// The keyboard calls this when the user taps stop.
    public func postStopRequested() {
        transport.post(.stopRequested)
    }

    /// The app iterates this stream and ends the recording for each element.
    public func stopRequested() -> AsyncStream<Void> {
        transport.notifications(named: .stopRequested)
    }
}
