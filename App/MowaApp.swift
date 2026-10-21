import MowaASR
import MowaCore
import MowaShared
import SwiftUI

@main
struct MowaApp: App {
    @State private var history: HistoryModel
    @State private var session: SessionController
    @State private var onboarding = OnboardingModel(
        store: try? SharedStore(appGroupIdentifier: MowaShared.appGroupIdentifier)
    )
    @Environment(\.scenePhase) private var scenePhase
    @State private var words = WordListModel(
        store: try? SharedStore(appGroupIdentifier: MowaShared.appGroupIdentifier)
    )
    @State private var models = ModelManager(store: ParakeetModelStore())

    init() {
        let store = try? SharedStore(appGroupIdentifier: MowaShared.appGroupIdentifier)
        let history = HistoryModel(
            store: SwiftDataHistoryStore.make(),
            isSecureField: { store.isSecureFieldFocused() },
            copy: { UIPasteboard.general.string = $0 }
        )
        _history = State(initialValue: history)
        _session = State(initialValue: AppSession.makeController(history: history))
    }

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 24) {
                OnboardingView(model: onboarding)
                Text(session.status.label)
                ModelView(models: models)
                WordListView(model: words)
                HistoryView(model: history)
            }
            .onOpenURL { session.handle(url: $0) }
            .onChange(of: scenePhase, initial: true) { onboarding.refresh() }
            .task { await session.observeStopRequests() }
        }
    }
}
