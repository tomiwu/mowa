import MowaASR
import MowaCore
import MowaShared
import SwiftUI

@main
struct MowaApp: App {
    @State private var session = AppSession.makeController()
    @State private var onboarding = OnboardingModel(
        store: try? SharedStore(appGroupIdentifier: MowaShared.appGroupIdentifier)
    )
    @Environment(\.scenePhase) private var scenePhase
    @State private var models = ModelManager(store: ParakeetModelStore())

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 24) {
                OnboardingView(model: onboarding)
                Text(session.status.label)
                ModelView(models: models)
            }
            .onOpenURL { session.handle(url: $0) }
            .onChange(of: scenePhase, initial: true) { onboarding.refresh() }
            .task { await session.observeStopRequests() }
        }
    }
}
