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
}
