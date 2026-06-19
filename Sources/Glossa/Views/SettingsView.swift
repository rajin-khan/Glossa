import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        Form {
            Section("Subtitles") {
                Picker("Target Language", selection: $store.targetLanguage) {
                    ForEach(TranslationLanguage.supported) { language in
                        Text(language.name).tag(language)
                    }
                }

                Picker("Capture Source", selection: $store.captureMode) {
                    ForEach(CaptureMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }

            Section("Privacy") {
                LabeledContent("Default Engine", value: "Local-first architecture")
                LabeledContent("Cloud Mode", value: "Not connected yet")
                LabeledContent("Audio Storage", value: "None")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
