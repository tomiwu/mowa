/// The text of one transcribed utterance.
public struct Transcript: Sendable, Equatable {
    /// BCP 47 code for a language that the engine did not detect.
    public static let undeterminedLanguage = "und"

    public let text: String
    public let languageCode: String

    public init(text: String, languageCode: String = Transcript.undeterminedLanguage) {
        self.text = text
        self.languageCode = languageCode
    }
}

/// Reasons why an engine cannot transcribe.
public enum TranscriptionError: Error, Equatable, Sendable {
    case modelNotInstalled
    case modelLoadFailed
    case transcriptionFailed
}

/// An engine that turns 16 kHz mono samples into text on the device.
///
/// Parakeet (FluidAudio) implements it. WhisperKit implements it in a later issue.
public protocol TranscriptionEngine: Sendable {
    func transcribe(_ samples: [Float]) async throws(TranscriptionError) -> Transcript
}
