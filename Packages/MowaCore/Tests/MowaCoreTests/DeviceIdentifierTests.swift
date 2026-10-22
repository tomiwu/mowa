import Testing

@testable import MowaCore

struct DeviceIdentifierTests {
    @Test func simulatorModelWins() {
        #expect(
            DeviceIdentifier.resolve(simulatorModel: "iPhone12,1", machine: "arm64") == "iPhone12,1"
        )
    }

    @Test func machineIsTheFallback() {
        #expect(
            DeviceIdentifier.resolve(simulatorModel: nil, machine: "iPhone14,2") == "iPhone14,2"
        )
    }

    @Test func currentIsNotEmpty() {
        #expect(!DeviceIdentifier.current.isEmpty)
    }
}
