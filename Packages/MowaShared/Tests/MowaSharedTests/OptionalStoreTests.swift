import Foundation
import Testing

@testable import MowaShared

struct OptionalStoreTests {
    private func makeStore() throws -> SharedStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return SharedStore(directory: directory)
    }

    @Test func missingStoreGivesDefaults() {
        let store: SharedStore? = nil
        store.recordKeyboard(hasFullAccess: true)
        #expect(store.sessionStatus() == .noSession)
        #expect(store.keyboardReport() == nil)
    }

    @Test func recordedReportIsRead() throws {
        let store: SharedStore? = try makeStore()
        #expect(store.keyboardReport() == nil)
        store.recordKeyboard(hasFullAccess: true)
        #expect(store.keyboardReport() == KeyboardReport(hasFullAccess: true))
    }

    @Test func sessionStatusIsRead() throws {
        let store = try makeStore()
        try store.writeSessionStatus(.recording)
        #expect(Optional(store).sessionStatus() == .recording)
    }

    @Test func detectWithoutReport() {
        let value = OnboardingState.detect(report: nil, microphone: .granted)
        #expect(
            value == OnboardingState(keyboardAdded: false, fullAccess: false, microphone: .granted)
        )
    }

    @Test func detectWithReport() {
        let value = OnboardingState.detect(
            report: KeyboardReport(hasFullAccess: true),
            microphone: .denied
        )
        #expect(
            value == OnboardingState(keyboardAdded: true, fullAccess: true, microphone: .denied)
        )
    }
}
