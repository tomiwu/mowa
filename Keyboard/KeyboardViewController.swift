import MowaShared
import SwiftUI
import UIKit

final class KeyboardViewController: UIInputViewController, KeyboardHost {
    private let notifier = DarwinNotifier(transport: SystemNotificationTransport())
    private var model = KeyboardModel(readStatus: { .noSession })
    private var observation: Task<Void, Never>?
    private var resultObservation: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        model = KeyboardModel(readStatus: readStatus())
        embed(KeyboardView(model: model) { [unowned self] action in action.perform(on: self) })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observation = Task { [model, notifier] in
            await model.observe(changes: notifier.sessionChanged())
        }
        resultObservation = Task { await observeResults() }
        report()
    }

    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        report()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        observation?.cancel()
        resultObservation?.cancel()
    }

    func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
    }

    func deleteBackward() {
        textDocumentProxy.deleteBackward()
    }

    func openStartURL() {
        let application = sequence(first: self as UIResponder, next: \.next)
            .compactMap { $0 as? UIApplication }
            .first
        _ = URL(string: MowaShared.startURLString).map {
            application?.open($0, options: [:], completionHandler: nil)
        }
    }

    func requestStop() {
        notifier.postStopRequested()
    }

    private func report() {
        let store = makeStore()
        store.recordKeyboard(hasFullAccess: hasFullAccess)
        store.recordInputFocus(isSecure: textDocumentProxy.isSecureTextEntry ?? true)
    }

    private func readStatus() -> @MainActor () -> SessionStatus {
        let store = makeStore()
        return { store.sessionStatus() }
    }

    private func observeResults() async {
        await ResultReceiver(store: makeStore()).observe(
            changes: notifier.resultReady(),
            host: self
        )
    }

    private func makeStore() -> SharedStore? {
        try? SharedStore(appGroupIdentifier: MowaShared.appGroupIdentifier)
    }

    private func embed(_ content: KeyboardView) {
        let host = UIHostingController(rootView: content)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
    }
}
