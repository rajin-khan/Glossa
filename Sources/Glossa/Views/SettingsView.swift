import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: GlossaStore
    @State private var selection = SettingsTab.launchSelection

    var body: some View {
        TabView(selection: $selection) {
            GeneralSettingsView(store: store)
                .tag(SettingsTab.general)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            AppearanceSettingsView(store: store)
                .tag(SettingsTab.appearance)
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }

            PrivacySettingsView(store: store)
                .tag(SettingsTab.privacy)
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }
        }
        .frame(width: 620, height: 540)
        .padding(.top, 8)
    }
}

private enum SettingsTab: String {
    case general
    case appearance
    case privacy

    static var launchSelection: SettingsTab {
        let prefix = "--settings-tab="
        guard let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix(prefix) }),
              let tab = SettingsTab.resolve(String(argument.dropFirst(prefix.count)))
        else {
            return .general
        }
        return tab
    }

    private static func resolve(_ rawValue: String) -> SettingsTab? {
        if rawValue == "overlay" {
            return .appearance
        }
        return SettingsTab(rawValue: rawValue)
    }
}

private struct GeneralSettingsView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        Form {
            Section("Translation") {
                Picker("Translate To", selection: $store.targetLanguage) {
                    ForEach(store.availableTargetLanguages) { language in
                        Text("\(language.name) · \(language.nativeName)")
                            .tag(language)
                    }
                }

                LabeledContent("Source Language", value: "Detect automatically")
            }

            Section("Bangla Fallback") {
                TextField("LibreTranslate URL", text: $store.fallbackTranslationURLString)
                    .textFieldStyle(.roundedBorder)

                Text("Bangla stays in Glossa even when Apple Translation does not support a pair. Add a local or bring-your-own LibreTranslate endpoint to translate unsupported pairs without OpenAI.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Listening") {
                Picker("Capture Source", selection: $store.captureMode) {
                    ForEach(CaptureMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                Text(store.captureMode.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Local Speech Model") {
                LocalModelPreparationView(store: store)
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 12)
    }
}

struct AppearanceSettingsView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        Form {
            Section("Preview") {
                OverlayPreviewCard(store: store)
            }

            Section("Typography") {
                Toggle("Show original speech below translation", isOn: $store.showsSourceText)

                Picker("Preset", selection: $store.overlayTextSize) {
                    ForEach(OverlayTextSize.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Font", selection: $store.overlayFontStyle) {
                    ForEach(OverlayFontStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)

                SliderRow(
                    title: "Subtitle Size",
                    value: $store.overlayFontSize,
                    range: 12...44,
                    step: 1,
                    valueLabel: "\(Int(store.overlayFontSize)) pt"
                )
            }

            Section("Floating Window") {
                LabeledContent("Visibility", value: store.overlayVisible ? "Shown" : "Hidden")

                SliderRow(
                    title: "Window Width",
                    value: $store.overlayWidthFraction,
                    range: 0.25...0.88,
                    step: 0.01,
                    valueLabel: "\(Int(store.overlayWidthFraction * 100))%"
                )

                SliderRow(
                    title: "Background",
                    value: $store.overlayBackgroundOpacity,
                    range: 0.03...0.78,
                    step: 0.01,
                    valueLabel: "\(Int(store.overlayBackgroundOpacity * 100))%"
                )

                SliderRow(
                    title: "Corners",
                    value: $store.overlayCornerRadius,
                    range: 6...30,
                    step: 1,
                    valueLabel: "\(Int(store.overlayCornerRadius)) px"
                )

                HStack {
                    Button(store.overlayVisible ? "Hide Overlay" : "Show Overlay") {
                        store.toggleOverlay()
                    }

                    Button("Preview Motion") {
                        store.captureMode = .preview
                        if !store.isListening {
                            store.startListening()
                        }
                    }

                    Button("Reset Position") {
                        store.resetOverlayPosition()
                    }

                    Spacer()

                    Button("Reset Appearance") {
                        store.resetOverlayAppearance()
                    }
                }

                Text("Drag the subtitle window from its background. Reset Position returns it to the lower center.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 12)
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(valueLabel)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

private struct OverlayPreviewCard: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        VStack(spacing: 8) {
            Text("Audio stays on your Mac.")
                .font(.system(size: min(30, store.overlayFontSize), weight: .semibold, design: store.overlayFontStyle.design))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            if store.showsSourceText {
                Text("Le son reste sur votre Mac.")
                    .font(.system(size: max(10, min(18, store.overlayFontSize * 0.48)), weight: .medium, design: store.overlayFontStyle.design))
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: store.overlayCornerRadius))
        .background(.black.opacity(store.overlayBackgroundOpacity), in: RoundedRectangle(cornerRadius: store.overlayCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: store.overlayCornerRadius)
                .strokeBorder(.white.opacity(0.12))
        }
        .preferredColorScheme(.dark)
    }
}

private struct PrivacySettingsView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        Form {
            Section("Local by Default") {
                LabeledContent("Speech Recognition", value: "WhisperKit on this Mac")
                LabeledContent("Translation", value: "Apple first, fallback optional")
                LabeledContent("Audio Storage", value: "Never stored")
                LabeledContent("Account or API Key", value: "Not required")
            }

            Section("Capture Permissions") {
                settingsPermissionRow(
                    title: "System Audio",
                    state: store.permissions.screenRecording
                ) {
                    Task { await store.requestScreenRecordingPermission() }
                }

                settingsPermissionRow(
                    title: "Microphone",
                    state: store.permissions.microphone
                ) {
                    Task { await store.requestMicrophonePermission() }
                }

                HStack {
                    Button("Refresh") {
                        Task { await store.refreshPermissions() }
                    }
                    Spacer()
                    if !store.permissions.screenRecording.isReady {
                        Button("Restart Glossa") {
                            store.restartApplication()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 12)
    }

    private func settingsPermissionRow(
        title: String,
        state: CapturePermissionState,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            LabeledContent(title, value: state.label)
            if state.isReady {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.teal)
                    .accessibilityLabel("Ready")
            } else {
                Button("Grant Access", action: action)
            }
        }
    }
}
