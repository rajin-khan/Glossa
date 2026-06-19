import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var store: GlossaStore
    let overlayController: SubtitleOverlayController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(store.isListening ? "Pause Listening" : "Start Listening") {
            store.toggleListening()
            if store.isListening {
                overlayController.show()
            }
        }

        Button(store.overlayVisible ? "Hide Subtitles" : "Show Subtitles") {
            overlayController.toggle()
        }

        Divider()

        Picker("Target", selection: $store.targetLanguage) {
            ForEach(TranslationLanguage.supported) { language in
                Text(language.name).tag(language)
            }
        }

        Picker("Capture", selection: $store.captureMode) {
            ForEach(CaptureMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }

        Divider()

        Button("Open Glossa") {
            openWindow(id: "main")
        }

        Button("Quit Glossa") {
            NSApp.terminate(nil)
        }
    }
}
