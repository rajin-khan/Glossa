import SwiftUI

struct MainPanelHeader: View {
    let listeningState: ListeningState

    var body: some View {
        HStack(spacing: 16) {
            GlossaAppIconView(size: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text("Glossa")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                Text("Private captions for Mac audio.")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()
            ListeningBadge(state: listeningState)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                LinearGradient(
                    colors: [.white.opacity(0.08), .black.opacity(0.20)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
        }
    }
}

struct SessionControls: View {
    @Binding var captureMode: CaptureMode
    @Binding var targetLanguage: TranslationLanguage
    let availableLanguages: [TranslationLanguage]
    let isListening: Bool
    let toggleListening: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Listen To")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker("Capture", selection: $captureMode) {
                    ForEach(CaptureMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .frame(maxWidth: 340)

            VStack(alignment: .leading, spacing: 6) {
                Text("Translate Into")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker("Translate to", selection: $targetLanguage) {
                    ForEach(availableLanguages) { language in
                        Text("\(language.name) · \(language.nativeName)")
                            .tag(language)
                    }
                }
            }
            .frame(width: 230)

            Spacer()

            Button(action: toggleListening) {
                Label(
                    isListening ? "Pause" : "Start",
                    systemImage: isListening ? "pause.fill" : "play.fill"
                )
                .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.space, modifiers: [])
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.black.opacity(0.32))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
        }
    }
}

struct MainPanelToolbar: ToolbarContent {
    let overlayVisible: Bool
    let toggleOverlay: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button(action: toggleOverlay) {
                Label(
                    overlayVisible ? "Hide Overlay" : "Show Overlay",
                    systemImage: overlayVisible ? "rectangle.slash" : "rectangle.on.rectangle"
                )
                .contentTransition(.symbolEffect(.replace))
            }
            .help(overlayVisible ? "Hide subtitle overlay" : "Show subtitle overlay")

            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
