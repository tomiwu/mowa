/// One utterance of speech, as 16 kHz mono samples.
public struct SpeechSegment: Sendable, Equatable {
    public let samples: [Float]

    public init(samples: [Float]) {
        self.samples = samples
    }
}

/// Reasons why the speech pipeline cannot continue.
public enum SpeechPipelineError: Error, Equatable, Sendable {
    case detectorUnavailable
    case detectionFailed
}

/// Gives the speech probability of one chunk of audio. The VAD model implements it.
public protocol SpeechActivityDetector: Sendable {
    func probability(of chunk: [Float]) async throws(SpeechPipelineError) -> Float
}

/// Runs `body` and reports each error of it as `failure`.
func mapFailure<Value>(
    to failure: SpeechPipelineError,
    _ body: () async throws -> Value
) async throws(SpeechPipelineError) -> Value {
    do {
        return try await body()
    } catch {
        throw failure
    }
}
