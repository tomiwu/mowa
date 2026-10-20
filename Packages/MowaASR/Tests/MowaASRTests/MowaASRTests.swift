import Testing

@testable import MowaASR

struct MowaASRTests {
    @Test func namespaceExists() {
        #expect(String(describing: MowaASR.self) == "MowaASR")
    }
}
