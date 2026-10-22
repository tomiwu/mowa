import Testing

@testable import MowaCore

@Suite("Memory budget")
struct MemoryBudgetTests {
    @Test func modelLoadBudgetIsOnePointTwoGigabytes() {
        #expect(MemoryBudget.modelLoad.minimumBytes == 1_200_000_000)
    }

    @Test func refusesLessMemoryThanTheBudget() {
        #expect(!MemoryBudget(minimumBytes: 10).allows(availableBytes: 9))
    }

    @Test func allowsTheBudgetAndMore() {
        let budget = MemoryBudget(minimumBytes: 10)
        #expect(budget.allows(availableBytes: 10))
        #expect(budget.allows(availableBytes: 11))
    }

    @Test func systemReadingHasNoLimitOffDevice() {
        #expect(MemoryBudget.systemAvailableBytes() > 0)
    }
}
