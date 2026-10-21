/// Names of the Darwin notifications that the app and the keyboard send.
public enum DarwinNotificationName: String, Sendable {
    case resultReady = "group.com.tomiwu.mowa.result-ready"
}

/// Low-level channel for Darwin notifications. Tests use a fake.
public protocol NotificationTransport: Sendable {
    func post(_ name: DarwinNotificationName)
    func notifications(named name: DarwinNotificationName) -> AsyncStream<Void>
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
}
