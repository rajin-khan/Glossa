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

                Picker("Transcription Engine", selection: $store.transcriptionProvider) {
                    ForEach(TranscriptionProviderKind.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }

                Text(store.transcriptionProvider.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Privacy") {
                LabeledContent("Default Engine", value: "WhisperKit Local")
                LabeledContent("Model", value: "Tiny multilingual")
                LabeledContent("Audio Storage", value: "None")
                LabeledContent("API Cost", value: "None")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
