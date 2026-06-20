import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var store: GlossaStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button {
            store.toggleListening()
        } label: {
            Label(
                store.isListening ? "Pause Listening" : "Start Listening",
                systemImage: store.isListening ? "pause.fill" : "play.fill"
            )
        }

        Button {
            store.toggleOverlay()
        } label: {
            Label(
                store.overlayVisible ? "Hide Overlay" : "Show Overlay",
                systemImage: store.overlayVisible ? "rectangle.slash" : "rectangle.on.rectangle"
            )
        }

        Divider()

        Picker("Translate To", selection: $store.targetLanguage) {
            ForEach(store.availableTargetLanguages) { language in
                Text(language.name).tag(language)
            }
        }

        Picker("Listen To", selection: $store.captureMode) {
            ForEach(CaptureMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }

        if needsCapturePermission {
            Divider()
            Button {
                requestActivePermission()
            } label: {
                Label("Grant Capture Access", systemImage: "exclamationmark.triangle")
            }
        }

        Divider()

        Button {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        } label: {
            Label("Open Glossa", systemImage: "macwindow")
        }

        SettingsLink {
            Label("Settings…", systemImage: "gearshape")
        }

        Button {
            NSApp.terminate(nil)
        } label: {
            Label("Quit Glossa", systemImage: "power")
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
}
