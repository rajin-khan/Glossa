import AppKit
import SwiftUI

struct MenuBarFooter: View {
    let openMain: () -> Void
    let openSettings: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: openMain) {
                Label("Open Glossa", systemImage: "macwindow")
            }

            Button(action: openSettings) {
                Image(systemName: "gearshape")
            }
            .help("Open settings")

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit Glossa")
        }
        .font(.caption.weight(.medium))
    }
}
