import Foundation
import Testing

@testable import MowaCore

@Suite("Model selection")
struct ModelSelectionTests {
    private func makeStorage() -> ModelChoiceStorage {
        ModelChoiceStorage(suiteName: "mowa.test.\(UUID().uuidString)")
    }

    @Test func storageGivesParakeetWhenNothingIsSaved() {
        #expect(makeStorage().choice == .parakeet)
    }

    @Test func storageKeepsTheChoice() {
        let storage = makeStorage()
        storage.choice = .whisper
        #expect(storage.choice == .whisper)
    }

    @Test func storageIgnoresAnUnknownValue() {
        let name = "mowa.test.\(UUID().uuidString)"
        UserDefaults(suiteName: name)?.set("other", forKey: "modelChoice")
        #expect(ModelChoiceStorage(suiteName: name).choice == .parakeet)
    }

    @Test @MainActor func selectionSavesEachChange() {
        let storage = makeStorage()
        let selection = ModelSelection(storage: storage)
        selection.choice = .whisper
        #expect(storage.choice == .whisper)
        #expect(ModelSelection(storage: storage).choice == .whisper)
    }

    @Test func choicesHaveNamesAndIds() {
        #expect(ModelChoice.allCases.map(\.displayName).count == 2)
        #expect(ModelChoice.whisper.id == "whisper")
        #expect(ModelChoice.parakeet.displayName.contains("Parakeet"))
        #expect(ModelChoice.whisper.displayName.contains("Whisper"))
    }
}
