import MowaASR
import MowaCore
import MowaShared
import SwiftUI

@main
struct MowaApp: App {
    @State private var session = AppSession.makeController()
    @State private var models = ModelManager(store: ParakeetModelStore())

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 24) {
                Text(session.status.label)
                ModelView(models: models)
            }
            .onOpenURL { session.handle(url: $0) }
            .task { await session.observeStopRequests() }
        }
    }
}
