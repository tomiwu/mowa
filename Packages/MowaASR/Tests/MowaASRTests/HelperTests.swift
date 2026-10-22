import MowaCore
import Testing

@testable import MowaASR

private struct LoadError: Error {}

private actor Counter {
    var calls = 0
    func next() -> Int {
        calls += 1
        return calls
    }
}

@Suite struct LoadOnceTests {
    @Test func loadsAgainAfterReset() async throws {
        let counter = Counter()
        let loader = LoadOnce<Int>(isReady: { true }, load: { await counter.next() })
        _ = try await loader.get()
        await loader.reset()
        #expect(try await loader.get() == 2)
    }

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

@Suite struct LoadOnceMemoryTests {
    private func loader(available: UInt64, _ counter: Counter) -> LoadOnce<Int> {
        LoadOnce<Int>(
            isReady: { true },
            availableBytes: { available },
            budget: MemoryBudget(minimumBytes: 100),
            load: { await counter.next() }
        )
    }

    @Test func lowMemoryDoesNotCallLoad() async {
        let counter = Counter()
        let loader = loader(available: 99, counter)
        await #expect(throws: TranscriptionError.notEnoughMemory) { try await loader.get() }
        #expect(await counter.calls == 0)
    }

    @Test func enoughMemoryCallsLoadOnce() async throws {
        let counter = Counter()
        let loader = loader(available: 100, counter)
        _ = try await loader.get()
        _ = try await loader.get()
        #expect(await counter.calls == 1)
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
