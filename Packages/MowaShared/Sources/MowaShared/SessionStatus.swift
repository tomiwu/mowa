/// State of the dictation session that the keyboard shows.
///
/// The raw value is the label for the user.
public enum SessionStatus: String, Codable, Sendable {
    case noSession = "no session"
    case recording = "recording"
    case processing = "processing"

    /// Text of the status indicator.
    public var label: String { rawValue }
}
