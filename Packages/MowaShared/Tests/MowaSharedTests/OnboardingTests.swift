import Foundation
import Testing

@testable import MowaShared

struct OnboardingTests {
    private func state(
        _ keyboard: Bool,
        _ access: Bool,
        _ microphone: MicrophonePermission
    ) -> OnboardingState {
        OnboardingState(keyboardAdded: keyboard, fullAccess: access, microphone: microphone)
    }

    @Test func firstStepIsKeyboard() {
        #expect(state(false, false, .undetermined).currentStep == .keyboard)
    }

    @Test func fullAccessNeedsKeyboard() {
        let value = state(false, true, .granted)
        #expect(!value.isDone(.fullAccess))
        #expect(value.currentStep == .keyboard)
    }

    @Test func nextStepIsFullAccess() {
        #expect(state(true, false, .granted).currentStep == .fullAccess)
    }

    @Test func nextStepIsMicrophone() {
        #expect(state(true, true, .denied).currentStep == .microphone)
        #expect(state(true, true, .undetermined).currentStep == .microphone)
    }

    @Test func flowIsComplete() {
        let value = state(true, true, .granted)
        #expect(value.isComplete)
        #expect(value.currentStep == nil)
    }

    @Test func eachStepHasText() {
        for step in OnboardingStep.allCases {
            #expect(!step.title.isEmpty)
            #expect(!step.explanation.isEmpty)
        }
    }

    @Test func fullAccessTextGivesTheReason() {
        #expect(OnboardingStep.fullAccess.explanation.contains("App Group"))
    }

    @Test func keyboardReportRoundTrips() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = SharedStore(directory: directory)
        #expect(try store.readKeyboardReport() == nil)
        try store.writeKeyboardReport(KeyboardReport(hasFullAccess: true))
        #expect(try store.readKeyboardReport() == KeyboardReport(hasFullAccess: true))
    }
}
