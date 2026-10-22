import MowaCore
import SwiftUI

/// Lets the user select the model. Shows the model size, the download progress and the buttons
/// to download and delete.
struct ModelView: View {
    let selection: ModelSelection
    let managers: [ModelChoice: ModelManager]

    var body: some View {
        VStack(spacing: 12) {
            Picker("Model", selection: Bindable(selection).choice) {
                ForEach(ModelChoice.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            ManagerView(name: selection.choice.displayName, models: managers[selection.choice])
        }
        .padding()
    }
}

/// Shows the state of the files of one model.
private struct ManagerView: View {
    let name: String
    let models: ModelManager?

    var body: some View {
        if let models {
            VStack(spacing: 12) {
                Text("\(name) (\(models.sizeText))")
                Text(models.state.label)
                ProgressView(value: models.state.fraction)
                Button("Download") { Task { await models.download() } }
                    .disabled(!models.state.canDownload)
                Button("Delete", role: .destructive) { models.delete() }
                    .disabled(!models.state.canDelete)
            }
        }
    }
}
