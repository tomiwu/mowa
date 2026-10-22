import Testing

@testable import MowaCore

@Suite("License list")
struct LicenseListTests {
    @Test func whisperHasTheMitLicense() {
        let whisper = LicenseList.entries.filter { $0.name.contains("Whisper") }
        #expect(whisper.count == 2)
        #expect(whisper.allSatisfy { $0.license == "MIT" })
    }

    @Test func parakeetKeepsItsAttribution() {
        let entry = LicenseList.entries.first { $0.name.contains("Parakeet") }
        #expect(entry?.license == "CC-BY-4.0")
        #expect(entry?.id == entry?.name)
    }

    @Test func everyEntryNamesItsAuthor() {
        #expect(LicenseList.entries.allSatisfy { !$0.author.isEmpty })
    }

    @Test func requiredLicensesHaveTheRightAuthor() {
        let authors = Dictionary(
            uniqueKeysWithValues: LicenseList.entries.map { ($0.name, $0.author) }
        )
        #expect(authors["Parakeet TDT 0.6B v3"] == "NVIDIA")
        #expect(authors["FluidAudio"] == "Fluid Inference")
        #expect(authors["WhisperKit"] == "Argmax, Inc.")
    }
}
