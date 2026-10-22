/// The ASR model that the user selects in Settings.
public enum ModelChoice: String, CaseIterable, Identifiable, Sendable {
    case parakeet
    case whisper

    /// The model that the app uses until the user selects another one.
    public static let standard = Self.parakeet

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .parakeet: "Parakeet TDT 0.6B v3"
        case .whisper: "Whisper large-v3 turbo"
        }
    }
}
