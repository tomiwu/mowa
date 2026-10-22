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
    @State private var cleanUp = CleanUpModel(
        store: try? SharedStore(appGroupIdentifier: MowaShared.appGroupIdentifier)
    )
    @State private var selection = ModelSelection(storage: AppSession.modelChoiceStorage)
    @State private var managers = AppSession.makeManagers()

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

    private func releaseModel(in phase: ScenePhase) {
        if phase == .background { AppSession.releaseModel() }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                VStack(spacing: 24) {
                    OnboardingView(model: onboarding)
                    Text(session.status.label)
                    ModelView(selection: selection, managers: managers)
                    CleanUpView(model: cleanUp)
                    NavigationLink("Licenses") { LicensesView() }
                    WordListView(model: words)
                    HistoryView(model: history)
                }
            }
            .onOpenURL { session.handle(url: $0) }
            .onChange(of: scenePhase, initial: true) { onboarding.refresh() }
            .onChange(of: scenePhase) { _, phase in releaseModel(in: phase) }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.didReceiveMemoryWarningNotification
                )
            ) { _ in AppSession.releaseModel() }
            .task { await session.observeStopRequests() }
        }
    }
}
