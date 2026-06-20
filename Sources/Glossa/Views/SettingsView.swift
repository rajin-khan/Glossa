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

            OverlaySettingsView(store: store)
                .tag(SettingsTab.overlay)
                .tabItem {
                    Label("Overlay", systemImage: "captions.bubble")
                }

            PrivacySettingsView(store: store)
                .tag(SettingsTab.privacy)
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }
        }
        .frame(width: 560, height: 420)
        .padding(.top, 8)
    }
}

private enum SettingsTab: String {
    case general
    case overlay
    case privacy

    static var launchSelection: SettingsTab {
        let prefix = "--settings-tab="
        guard let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix(prefix) }),
              let tab = SettingsTab(rawValue: String(argument.dropFirst(prefix.count)))
        else {
            return .general
        }
        return tab
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

private struct OverlaySettingsView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        Form {
            Section("Captions") {
                Toggle("Show original speech below translation", isOn: $store.showsSourceText)

                Picker("Text Size", selection: $store.overlayTextSize) {
                    ForEach(OverlayTextSize.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Floating Overlay") {
                LabeledContent("Visibility", value: store.overlayVisible ? "Shown" : "Hidden")

                Button(store.overlayVisible ? "Hide Overlay" : "Show Overlay") {
                    store.toggleOverlay()
                }

                Text("Drag the overlay from its background to place it anywhere on screen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 12)
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
