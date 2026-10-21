/// What the keyboard needs from its host. The view controller implements it.
@MainActor
public protocol KeyboardHost: AnyObject {
    func insertText(_ text: String)
    func deleteBackward()
    func advanceToNextInputMode()
    func openStartURL()
    func requestStop()
}

/// The effect of one key on the host.
public struct KeyAction: Sendable {
    private let run: @MainActor @Sendable (any KeyboardHost) -> Void

    private init(run: @escaping @MainActor @Sendable (any KeyboardHost) -> Void) {
        self.run = run
    }

    @MainActor
    public func perform(on host: any KeyboardHost) {
        run(host)
    }

    public static let space = Self { $0.insertText(" ") }
    public static let returnKey = Self { $0.insertText("\n") }
    public static let delete = Self { $0.deleteBackward() }
    public static let nextKeyboard = Self { $0.advanceToNextInputMode() }

    /// Opens the app when there is no session. Otherwise it stops the session.
    public static func mic(status: SessionStatus) -> Self {
        status == .noSession ? Self { $0.openStartURL() } : Self { $0.requestStop() }
    }

    public static func insert(_ text: String) -> Self {
        Self { $0.insertText(text) }
    }
}
