import SwiftUI

struct MenuBarConfiguration: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        HStack(spacing: 8) {
            MenuBarPicker(
                title: "Translate",
                systemImage: "character.bubble"
            ) {
                Picker("Translate", selection: $store.targetLanguage) {
                    ForEach(store.availableTargetLanguages) { language in
                        Text("\(language.name) · \(language.nativeName)")
                            .tag(language)
                    }
                }
                .labelsHidden()
            }

            MenuBarPicker(
                title: "Listen",
                systemImage: store.captureMode.systemImage
            ) {
                Picker("Capture", selection: $store.captureMode) {
                    ForEach(CaptureMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .labelsHidden()
            }
        }
    }
}

private struct MenuBarPicker<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: systemImage)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)

            content
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))
    }
}
