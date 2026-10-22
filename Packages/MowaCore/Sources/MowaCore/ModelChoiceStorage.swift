import Foundation

/// Keeps the selected ASR model in the user defaults of one suite.
public struct ModelChoiceStorage: Sendable {
    private static let key = "modelChoice"
    private let suiteName: String

    public init(suiteName: String) {
        self.suiteName = suiteName
    }

    /// The saved choice. It is the standard choice when nothing valid is saved.
    public var choice: ModelChoice {
        get {
            defaults.string(forKey: Self.key).flatMap(ModelChoice.init(rawValue:)) ?? .standard
        }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Self.key) }
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
}
