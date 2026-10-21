import MowaShared
import SwiftUI

@main
struct MowaApp: App {
    @State private var session = AppSession.makeController()

    var body: some Scene {
        WindowGroup {
            Text(session.status.label)
                .onOpenURL { session.handle(url: $0) }
                .task { await session.observeStopRequests() }
        }
    }
}
