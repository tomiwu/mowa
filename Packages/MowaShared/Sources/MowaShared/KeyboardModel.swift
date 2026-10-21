public import Observation

/// State of the keyboard view.
@MainActor
@Observable
public final class KeyboardModel {
    public private(set) var status = SessionStatus.noSession
    @ObservationIgnored private let readStatus: @MainActor () -> SessionStatus

    public init(readStatus: @escaping @MainActor () -> SessionStatus) {
        self.readStatus = readStatus
    }

    public var micAction: KeyAction {
        .mic(status: status)
    }

    public func refresh() {
        status = readStatus()
    }

    /// Reads the status now and after each change notification.
    public func observe(changes: AsyncStream<Void>) async {
        refresh()
        for await _ in changes {
            refresh()
        }
    }
}
