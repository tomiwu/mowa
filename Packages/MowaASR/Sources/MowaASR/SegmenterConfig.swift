/// Settings of the speech segmenter. All durations are counted in chunks of `chunkSize` samples.
public struct SegmenterConfig: Sendable, Equatable {
    /// Samples in one chunk. The Silero VAD model reads 4096 samples (256 ms at 16 kHz).
    public static let chunkSize = 4096

    /// Speech starts when the probability is at or above this value.
    public var startThreshold: Float
    /// A chunk counts as silence when the probability is below this value.
    public var endThreshold: Float
    /// Silent chunks in a row that end an utterance.
    public var minSilenceChunks: Int
    /// Chunks before the start of speech that stay in the segment.
    public var prerollChunks: Int

    public static let standard = Self(
        startThreshold: 0.85,
        endThreshold: 0.7,
        minSilenceChunks: 2,
        prerollChunks: 1
    )

    public init(
        startThreshold: Float,
        endThreshold: Float,
        minSilenceChunks: Int,
        prerollChunks: Int
    ) {
        self.startThreshold = startThreshold
        self.endThreshold = endThreshold
        self.minSilenceChunks = minSilenceChunks
        self.prerollChunks = prerollChunks
    }
}
