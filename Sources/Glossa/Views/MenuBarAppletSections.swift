import AppKit
import SwiftUI

struct MenuBarPermission {
    let title: String
    let detail: String
}

struct MenuBarHeader: View {
    let state: ListeningState

    var body: some View {
        HStack(spacing: 11) {
            GlossaAppIconView(size: 34)

            VStack(alignment: .leading, spacing: 2) {
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
                    isListening ? "Pause" : "Start",
                    systemImage: isListening ? "pause.fill" : "play.fill"
                )
                .frame(maxWidth: .infinity)
                .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(action: toggleOverlay) {
                Image(systemName: overlayVisible ? "rectangle.slash" : "captions.bubble")
                    .frame(width: 34)
                    .contentTransition(.symbolEffect(.replace))
            }
            .controlSize(.large)
            .help(overlayVisible ? "Hide overlay" : "Show overlay")
        }
    }
}

struct MenuBarControlCard: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        VStack(spacing: 9) {
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
                        Label(mode.rawValue, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
        }
        .padding(10)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.09))
        }
    }
}

struct MenuBarLineCard: View {
    let languageName: String
    let translatedText: String?
    let sourceText: String?
    let subtitleID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Live line", systemImage: "text.bubble")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(languageName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(translatedText ?? "Ready to carry the next line.")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .lineLimit(3)
                .minimumScaleFactor(0.78)
                .id(subtitleID)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

            if let sourceText {
                Text(sourceText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .transition(.opacity)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.12))
        }
        .animation(.easeInOut(duration: 0.22), value: subtitleID)
    }
}

struct MenuBarPermissionCard: View {
    let permission: MenuBarPermission
    let request: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(permission.title)
                    .font(.callout.weight(.semibold))
                Text(permission.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button("Open", action: request)
        }
        .padding(12)
        .background(.yellow.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(.yellow.opacity(0.22))
        }
    }
}

struct MenuBarAppearanceStrip: View {
    @ObservedObject var store: GlossaStore
    let openSettings: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Label("\(Int(store.overlayScale * 100))%", systemImage: "textformat.size")
            Spacer()
            Text("\(Int(store.overlayPrimaryFontSize)) pt")
            Button(action: openSettings) {
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
}

struct MenuBarFooter: View {
    let openMain: () -> Void
    let openSettings: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: openMain) {
                Label("Open", systemImage: "macwindow")
            }

            Button(action: openSettings) {
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
}

