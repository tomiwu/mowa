/// Gives the results of the app to the host text field of the keyboard.
@MainActor
public struct ResultReceiver {
    private let store: SharedStore?

    public init(store: SharedStore?) {
        self.store = store
    }

    /// Inserts the stored result into the host and removes it from the store.
    public func deliver(to host: any KeyboardHost) {
        guard let result = try? store?.readResult() else { return }
        store?.clearResult()
        KeyAction.insert(result.text).perform(on: host)
    }

    /// Delivers a result for each notification of the app.
    public func observe(changes: AsyncStream<Void>, host: any KeyboardHost) async {
        for await _ in changes {
            deliver(to: host)
        }
    }
}
