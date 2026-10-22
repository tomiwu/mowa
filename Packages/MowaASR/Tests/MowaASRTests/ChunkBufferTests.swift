import Testing

@testable import MowaASR

struct ChunkBufferTests {
    @Test func keepsLessThanOneChunkPending() {
        var buffer = ChunkBuffer(chunkSize: 4)
        #expect(buffer.append([1, 2, 3]).isEmpty)
        #expect(buffer.pendingCount == 3)
        #expect(buffer.append([4, 5, 6, 7, 8, 9]) == [[1, 2, 3, 4], [5, 6, 7, 8]])
        #expect(buffer.pendingCount == 1)
    }

    @Test func longInputLeavesOnlyTheRemainder() {
        var buffer = ChunkBuffer(chunkSize: 4)
        let chunks = buffer.append([Float](repeating: 1, count: 4 * 1000 + 2))
        #expect(chunks.count == 1000)
        #expect(buffer.pendingCount == 2)
    }

    @Test func flushPadsAndEmptiesTheBuffer() {
        var buffer = ChunkBuffer(chunkSize: 4)
        #expect(buffer.flush() == nil)
        _ = buffer.append([1, 2])
        #expect(buffer.flush() == [1, 2, 0, 0])
        #expect(buffer.pendingCount == 0)
    }
}
