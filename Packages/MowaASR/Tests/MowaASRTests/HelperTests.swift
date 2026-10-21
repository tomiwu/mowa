import MowaCore
import Testing

@testable import MowaASR

private struct LoadError: Error {}

private actor Counter {
    var count = 0
    func next() -> Int {
        count += 1
        return count
    }
}

@Suite struct LoadOnceTests {
    @Test func missingFilesGiveNotInstalled() async {
        let loader = LoadOnce<Int>(isReady: { false }, load: { 1 })
        await #expect(throws: TranscriptionError.modelNotInstalled) { try await loader.get() }
    }

    @Test func failedLoadGivesLoadFailed() async {
        let loader = LoadOnce<Int>(isReady: { true }, load: { throw LoadError() })
        await #expect(throws: TranscriptionError.modelLoadFailed) { try await loader.get() }
    }

    @Test func loadsOnlyOnce() async throws {
        let counter = Counter()
        let loader = LoadOnce<Int>(isReady: { true }, load: { await counter.next() })
        let first = try await loader.get()
        let second = try await loader.get()
        #expect(first == 1)
        #expect(second == 1)
    }
}

@Suite struct ProgressStreamTests {
    @Test func yieldsValuesThenEnds() async throws {
        let stream = progressStream { report in
            report(0.5)
            report(1)
        }
        var values: [Double] = []
        for try await value in stream { values.append(value) }
        #expect(values == [0.5, 1])
    }

    @Test func throwsTheErrorOfTheOperation() async {
        let stream = progressStream { _ in throw LoadError() }
        await #expect(throws: LoadError.self) {
            for try await _ in stream {}
        }
    }
}
