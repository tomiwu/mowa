import MowaShared
import SwiftUI

/// Guides the user through the keyboard, Full Access and microphone steps.
struct OnboardingView: View {
    let model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepRow(step: .keyboard, done: model.state.isDone(.keyboard)) {
                Button("Open Settings") { model.openSettings() }
            }
            StepRow(step: .fullAccess, done: model.state.isDone(.fullAccess)) {
                Button("Open Settings") { model.openSettings() }
            }
            StepRow(step: .microphone, done: model.state.isDone(.microphone)) {
                Button("Allow microphone") { Task { await model.requestMicrophone() } }
            }
            Text(model.state.isComplete ? Self.readyText : Self.hintText)
        }
        .padding()
    }

    private static let readyText =
        "Ready. Open any text field, switch to the Mowa keyboard and tap the microphone."
    private static let hintText =
        "Open the Mowa keyboard once, then return here. The app checks the steps by itself."
}

private struct StepRow<Action: View>: View {
    let step: OnboardingStep
    let done: Bool
    @ViewBuilder let action: Action

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(step.title, systemImage: done ? "checkmark.circle.fill" : "circle")
            Text(step.explanation).font(.footnote)
            action.disabled(done)
        }
    }
}
