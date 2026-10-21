/// Reasons why the recorder cannot start.
public enum AudioRecorderError: Error, Equatable, Sendable {
    case permissionDenied
    case audioSessionFailed
}

/// Adapter for the microphone. The app implements it with the audio engine.
public protocol AudioRecorder: Sendable {
    func start() throws(AudioRecorderError)
    func stop()
}
