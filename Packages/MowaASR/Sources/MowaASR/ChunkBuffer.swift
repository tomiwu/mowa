/// Collects audio of any length and hands it out in chunks of a fixed size.
struct ChunkBuffer: Sendable {
    private let chunkSize: Int
    private var pending: [Float] = []

    /// Samples that wait for the next full chunk. Always less than one chunk.
    var pendingCount: Int { pending.count }

    init(chunkSize: Int) {
        self.chunkSize = chunkSize
    }

    /// Adds samples. Returns all full chunks.
    mutating func append(_ samples: [Float]) -> [[Float]] {
        pending += samples
        let count = pending.count / chunkSize
        let chunks = (0..<count).map { Array(pending[$0 * chunkSize..<($0 + 1) * chunkSize]) }
        pending.removeFirst(count * chunkSize)
        return chunks
    }

    /// Returns the rest as one chunk, padded with silence. Returns nil when nothing is left.
    mutating func flush() -> [Float]? {
        guard !pending.isEmpty else { return nil }
        let chunk = pending + [Float](repeating: 0, count: chunkSize - pending.count)
        pending = []
        return chunk
    }
}
