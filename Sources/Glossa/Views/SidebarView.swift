import SwiftUI

struct SidebarView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        List {
            Section {
                Label("Live Subtitles", systemImage: "captions.bubble")
                Label("Languages", systemImage: "globe")
                Label("Privacy", systemImage: "lock.shield")
            }

            Section("Capture") {
                ForEach(CaptureMode.allCases) { mode in
                    Button {
                        store.captureMode = mode
                    } label: {
                        Label(mode.rawValue, systemImage: icon(for: mode))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(store.captureMode == mode ? .primary : .secondary)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Glossa")
    }

    private func icon(for mode: CaptureMode) -> String {
        switch mode {
        case .systemAudio:
            "speaker.wave.2"
        case .microphone:
            "mic"
        case .preview:
            "play.rectangle"
        }
    }
}
