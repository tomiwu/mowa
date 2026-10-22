/// Settings of the speech segmenter. All durations are counted in chunks of `chunkSize` samples.
public struct SegmenterConfig: Sendable, Equatable {
    /// Samples in one chunk. The Silero VAD model reads 4096 samples (256 ms at 16 kHz).
    public static let chunkSize = 4096

    /// Longest utterance in seconds. The segmenter cuts a longer utterance at this limit.
    public static let maxUtteranceSeconds = 15
    /// Sample rate of the audio that the pipeline reads.
    public static let sampleRate = 16_000
    /// Most chunks in one utterance. 15 s at 16 kHz is 58 chunks of 4096 samples (14.85 s).
    public static let maxUtteranceChunks = maxUtteranceSeconds * sampleRate / chunkSize
    /// Most recorder buffers that wait in the record stream. Older buffers are dropped.
    public static let streamBufferLimit = 256

    /// Speech starts when the probability is at or above this value.
    public var startThreshold: Float
    /// A chunk counts as silence when the probability is below this value.
    public var endThreshold: Float
    /// Silent chunks in a row that end an utterance.
    public var minSilenceChunks: Int
    /// Chunks before the start of speech that stay in the segment.
    public var prerollChunks: Int
    /// Chunks (with preroll) at which an open utterance is cut.
    public var maxChunks: Int

    public static let standard = Self(
        startThreshold: 0.85,
        endThreshold: 0.7,
        minSilenceChunks: 2,
        prerollChunks: 1,
        maxChunks: maxUtteranceChunks
    )

    public init(
        startThreshold: Float,
        endThreshold: Float,
        minSilenceChunks: Int,
        prerollChunks: Int,
        maxChunks: Int = Self.maxUtteranceChunks
    ) {
        self.startThreshold = startThreshold
        self.endThreshold = endThreshold
        self.minSilenceChunks = minSilenceChunks
        self.prerollChunks = prerollChunks
        self.maxChunks = maxChunks
    }
}
