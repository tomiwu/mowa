public import Observation

/// The model choice that Settings shows. A change is saved at once.
@MainActor
@Observable
public final class ModelSelection {
    @ObservationIgnored private let storage: ModelChoiceStorage

    public var choice: ModelChoice {
        didSet { storage.choice = choice }
    }

    public init(storage: ModelChoiceStorage) {
        self.storage = storage
        choice = storage.choice
    }
}
