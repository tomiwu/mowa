import MowaShared
import SwiftUI
import UIKit

final class KeyboardViewController: UIInputViewController, KeyboardHost {
    private let notifier = DarwinNotifier(transport: SystemNotificationTransport())
    private var model = KeyboardModel(readStatus: { .noSession })
    private var observation: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        model = KeyboardModel(readStatus: { [store = openStore()] in
            (try? store?.readSessionStatus()) ?? .noSession
        })
        embed(
            KeyboardView(model: model) { [weak self] action in
                guard let self else { return }
                action.perform(on: self)
            }
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observation = Task { [model, notifier] in
            await model.observe(changes: notifier.sessionChanged())
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        observation?.cancel()
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
        guard let url = URL(string: MowaShared.startURLString) else { return }
        application?.open(url, options: [:], completionHandler: nil)
    }

    func requestStop() {
        notifier.postStopRequested()
    }

    private func openStore() -> SharedStore? {
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
