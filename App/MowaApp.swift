import MowaShared
import SwiftUI

@main
struct MowaApp: App {
    var body: some Scene {
        WindowGroup {
            Text("\(MowaShared.urlScheme)://")
        }
    }
}
