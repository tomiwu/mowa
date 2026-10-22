import MowaShared
import Observation

/// Holds the clean-up setting for the screen and saves each change to the shared store.
@MainActor
@Observable
final class CleanUpModel {
    var isEnabled: Bool {
        didSet { try? store?.setCleanUp(enabled: isEnabled) }
    }
    private let store: SharedStore?

    init(store: SharedStore?) {
        self.store = store
        isEnabled = store?.isCleanUpEnabled ?? false
    }
}
