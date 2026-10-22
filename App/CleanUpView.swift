import SwiftUI

/// The Settings toggle for the text clean-up. It is OFF by default.
struct CleanUpView: View {
    let model: CleanUpModel

    var body: some View {
        Toggle("Clean up text on this device", isOn: Bindable(model).isEnabled)
            .padding(.horizontal)
    }
}
