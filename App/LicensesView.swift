import MowaCore
import SwiftUI

/// Lists the third-party components and their licenses.
struct LicensesView: View {
    var body: some View {
        List(LicenseList.entries) { entry in
            VStack(alignment: .leading) {
                Text("\(entry.name): \(entry.license)")
                Text(entry.note).font(.caption)
            }
        }
    }
}
