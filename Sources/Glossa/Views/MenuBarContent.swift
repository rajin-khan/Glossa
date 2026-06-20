import AppKit
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var store: GlossaStore
    var openMain: () -> Void = { }
    var openSettingsWindow: () -> Void = { }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            HStack(spacing: 8) {
                Button {
                    withAnimation(.snappy(duration: 0.18)) {
                        store.toggleListening()
                    }
                } label: {
                    Label(
                        store.isListening ? "Pause" : "Start",
                        systemImage: store.isListening ? "pause.fill" : "play.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    withAnimation(.snappy(duration: 0.18)) {
                        store.toggleOverlay()
                    }
                } label: {
                    Image(systemName: store.overlayVisible ? "rectangle.slash" : "captions.bubble")
                        .frame(width: 34)
                }
                .controlSize(.large)
                .help(store.overlayVisible ? "Hide overlay" : "Show overlay")
            }

            VStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Translate")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(store.targetLanguage.nativeName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.teal)
                    }
                    Picker("Translate", selection: $store.targetLanguage) {
                        ForEach(store.availableTargetLanguages) { language in
                            Text("\(language.name) · \(language.nativeName)")
                                .tag(language)
                        }
                    }
                    .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Capture")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Picker("Capture", selection: $store.captureMode) {
                        ForEach(CaptureMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: icon(for: mode))
                                .tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
            }
            .padding(10)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.white.opacity(0.09))
            }

            if needsCapturePermission {
                permissionCard
            } else {
                nowCard
            }

            appearanceStrip
            footer
        }
        .padding(14)
        .frame(width: 332)
        .background {
            ZStack {
                Color.glossaInk
                LinearGradient(
                    colors: [.white.opacity(0.10), .clear, .black.opacity(0.38)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                GlossaMarkView(size: 220)
                    .opacity(0.04)
                    .rotationEffect(.degrees(-8))
                    .offset(x: 94, y: 112)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 12) {
            GlossaAppIconView(size: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text("Glossa")
                    .font(.headline.weight(.semibold))
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            StatusPill(state: store.listeningState)
        }
    }

    private var nowCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Live line", systemImage: "text.bubble")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(store.targetLanguage.nativeName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(store.currentSubtitle?.translatedText ?? "Ready to carry the next line.")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .lineLimit(3)
                .minimumScaleFactor(0.78)

            if let source = sourcePreview {
                Text(source)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.12))
        }
    }

    private var permissionCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Capture access needed")
                    .font(.callout.weight(.semibold))
                Text(permissionDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Grant") {
                requestActivePermission()
            }
        }
        .padding(12)
        .background(.yellow.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.yellow.opacity(0.22))
        }
    }

    private var appearanceStrip: some View {
        HStack(spacing: 8) {
            Label("\(Int(store.overlayScale * 100))%", systemImage: "textformat.size")
            Spacer()
            Text("\(Int(store.overlayPrimaryFontSize)) pt")
            Button {
                openSettingsWindow()
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .buttonStyle(.borderless)
            .help("Open appearance settings")
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.045), in: Capsule())
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                openMain()
            } label: {
                Label("Open", systemImage: "macwindow")
            }

            Button {
                openSettingsWindow()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }

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

    private var sourcePreview: String? {
        guard store.showsSourceText,
              let segment = store.currentSubtitle,
              segment.sourceText != segment.translatedText
        else {
            return nil
        }
        return segment.sourceText
    }

    private var statusText: String {
        switch store.listeningState {
        case .idle:
            "Ready"
        case .starting:
            "Preparing speech"
        case .listening:
            "Listening"
        case .previewing:
            "Previewing"
        case .failed:
            "Needs attention"
        }
    }

    private var needsCapturePermission: Bool {
        switch store.captureMode {
        case .systemAudio:
            !store.permissions.screenRecording.isReady
        case .microphone:
            !store.permissions.microphone.isReady
        case .preview:
            false
        }
    }

    private var permissionDetail: String {
        switch store.captureMode {
        case .systemAudio:
            "Allow Screen & System Audio Recording, then restart once."
        case .microphone:
            "Allow microphone access to use the fallback source."
        case .preview:
            "Preview mode does not need capture access."
        }
    }

    private func requestActivePermission() {
        Task {
            switch store.captureMode {
            case .systemAudio:
                await store.requestScreenRecordingPermission()
            case .microphone:
                await store.requestMicrophonePermission()
            case .preview:
                break
            }
        }
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

private struct StatusPill: View {
    let state: ListeningState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.white.opacity(0.08), in: Capsule())
    }

    private var label: String {
        switch state {
        case .idle:
            "Ready"
        case .starting:
            "Starting"
        case .listening:
            "Live"
        case .previewing:
            "Preview"
        case .failed:
            "Issue"
        }
    }

    private var color: Color {
        switch state {
        case .idle:
            .secondary
        case .starting:
            .yellow
        case .listening, .previewing:
            .teal
        case .failed:
            .red
        }
    }
}
