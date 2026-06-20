import SwiftUI

struct GeneralSettingsView: View {
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

