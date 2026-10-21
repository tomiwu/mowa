import MowaShared
import SwiftUI

struct KeyboardView: View {
    let model: KeyboardModel
    let perform: (KeyAction) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(model.status.label)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("status")
            HStack(spacing: 8) {
                key("globe", label: "Next keyboard", action: .nextKeyboard)
                key(micSymbol, label: "Microphone", action: model.micAction)
                key("space", label: "Space", action: .space, grows: true)
                key("delete.left", label: "Delete", action: .delete)
                key("return", label: "Return", action: .returnKey)
            }
        }
        .padding(8)
    }

    private var micSymbol: String {
        model.status == .noSession ? "mic" : "stop.fill"
    }

    private func key(
        _ symbol: String,
        label: String,
        action: KeyAction,
        grows: Bool = false
    ) -> some View {
        Button {
            perform(action)
        } label: {
            Image(systemName: symbol)
                .frame(maxWidth: grows ? .infinity : 44, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .tint(.gray)
        .accessibilityLabel(label)
    }
}
