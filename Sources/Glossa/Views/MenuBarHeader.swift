import SwiftUI

struct MenuBarHeader: View {
    let state: ListeningState

    var body: some View {
        HStack(spacing: 10) {
            GlossaAppIconView(size: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text("Glossa")
                    .font(.headline.weight(.semibold))
                Text(state.menuDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
            ListeningStatusPill(state: state)
        }
    }
}

struct MenuBarTransportControls: View {
    let isListening: Bool
    let overlayVisible: Bool
    let toggleListening: () -> Void
    let toggleOverlay: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: toggleListening) {
                Label(
                    isListening ? "Pause" : "Start Listening",
                    systemImage: isListening ? "pause.fill" : "play.fill"
                )
                .frame(maxWidth: .infinity)
                .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(action: toggleOverlay) {
                Image(systemName: overlayVisible ? "rectangle.slash" : "captions.bubble")
                    .frame(width: 32)
                    .contentTransition(.symbolEffect(.replace))
            }
            .controlSize(.large)
            .help(overlayVisible ? "Hide subtitle overlay" : "Show subtitle overlay")
        }
    }
}
