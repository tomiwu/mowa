/// Cuts a stream of audio chunks into utterances with the speech probability of each chunk.
///
/// An utterance starts when the probability reaches the start threshold. It ends after enough
/// silent chunks in a row, or when `finish` is called (the user released the mic).
public struct SpeechSegmenter: Sendable {
    private let config: SegmenterConfig
    private var preroll: [[Float]] = []
    private var audio: [Float] = []
    private var inSpeech = false
    private var silentChunks = 0

    public init(config: SegmenterConfig = .standard) {
        self.config = config
    }

    /// Adds one chunk. Returns the utterance when this chunk ends it.
    public mutating func push(_ chunk: [Float], probability: Float) -> SpeechSegment? {
        inSpeech ? continueSpeech(chunk, probability) : waitForSpeech(chunk, probability)
    }

    /// Cuts the open utterance now. Returns nil when no speech is open.
    public mutating func finish() -> SpeechSegment? {
        inSpeech ? close() : nil
    }

    private mutating func waitForSpeech(_ chunk: [Float], _ probability: Float) -> SpeechSegment? {
        guard probability >= config.startThreshold else {
            preroll = Array((preroll + [chunk]).suffix(config.prerollChunks))
            return nil
        }
        inSpeech = true
        audio = preroll.flatMap { $0 } + chunk
        preroll = []
        return nil
    }

    private mutating func continueSpeech(_ chunk: [Float], _ probability: Float) -> SpeechSegment? {
        audio += chunk
        silentChunks = probability < config.endThreshold ? silentChunks + 1 : 0
        return silentChunks >= config.minSilenceChunks ? close() : nil
    }

    private mutating func close() -> SpeechSegment {
        let segment = SpeechSegment(samples: audio)
        audio = []
        inSpeech = false
        silentChunks = 0
        return segment
    }
}
