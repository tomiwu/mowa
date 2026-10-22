/// State of the dictation session that the keyboard shows.
///
/// The raw value is the label for the user.
public enum SessionStatus: String, Codable, Sendable {
    case noSession = "no session"
    case recording = "recording"
    case processing = "processing"
    case lowMemory = "not enough memory"

    /// Text of the status indicator.
    public var label: String { rawValue }
}
