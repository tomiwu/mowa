import MowaCore
import SwiftUI

/// Shows the model size, the download progress and the buttons to download and delete.
struct ModelView: View {
    let models: ModelManager

    var body: some View {
        VStack(spacing: 12) {
            Text("Parakeet TDT 0.6B v3 (\(models.sizeText))")
            Text(models.state.label)
            ProgressView(value: models.state.fraction)
            Button("Download") { Task { await models.download() } }
                .disabled(!models.state.canDownload)
            Button("Delete", role: .destructive) { models.delete() }
                .disabled(!models.state.canDelete)
        }
        .padding()
    }
}
