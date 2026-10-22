import Testing

@testable import MowaCore

struct TextCleanerTests {
    private let cleaner = TextCleaner()

    @Test func removesPolishFiller() {
        #expect(cleaner.clean("jadę yyy do Wrocławia") == "jadę do Wrocławia")
    }

    @Test func removesEnglishFillerWithComma() {
        #expect(cleaner.clean("I think, um, it works") == "I think, it works")
    }

    @Test func capitalizesAfterLeadingFiller() {
        #expect(cleaner.clean("eee dzień dobry") == "Dzień dobry")
    }

    @Test func keepsTextWithoutFiller() {
        #expect(cleaner.clean("Dzień dobry") == "Dzień dobry")
    }

    @Test func onlyFillerGivesEmptyText() {
        #expect(cleaner.clean("Yyy") == "")
    }

    @Test func emptyTextStaysEmpty() {
        #expect(cleaner.clean("") == "")
    }
}
