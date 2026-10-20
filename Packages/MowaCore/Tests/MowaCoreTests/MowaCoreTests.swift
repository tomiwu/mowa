import Testing

@testable import MowaCore

struct MowaCoreTests {
    @Test func namespaceExists() {
        #expect(String(describing: MowaCore.self) == "MowaCore")
    }
}
