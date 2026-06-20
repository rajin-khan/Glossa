import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var store: GlossaStore
    var openMain: () -> Void = { }
    var openSettingsWindow: () -> Void = { }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            MenuBarHeader(state: store.listeningState)

            MenuBarTransportControls(
                isListening: store.isListening,
                overlayVisible: store.overlayVisible,
                toggleListening: {
                    withAnimation(.snappy(duration: 0.18)) {
                        store.toggleListening()
                    }
                },
                toggleOverlay: {
                    withAnimation(.snappy(duration: 0.18)) {
                        store.toggleOverlay()
                    }
                }
            )

            MenuBarConfiguration(store: store)

            if let permission = activePermission {
                MenuBarPermissionCard(permission: permission) {
                    requestActivePermission()
                }
            } else {
                MenuBarLineCard(
                    languageName: store.targetLanguage.nativeName,
                    translatedText: store.currentSubtitle?.translatedText,
                    sourceText: sourcePreview,
                    subtitleID: store.currentSubtitle?.id
                )
            }

            Divider()
                .overlay(.white.opacity(0.08))
            MenuBarFooter(openMain: openMain, openSettings: openSettingsWindow)
        }
        .padding(12)
        .frame(width: 300)
        .background {
            ZStack {
                Color.glossaInk
                LinearGradient(
                    colors: [.white.opacity(0.07), .clear, .black.opacity(0.34)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .preferredColorScheme(.dark)
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

    private var activePermission: MenuBarPermission? {
        switch store.captureMode {
        case .systemAudio where !store.permissions.screenRecording.isReady:
            MenuBarPermission(
                title: "System audio access",
                detail: "Open Privacy & Security, allow Glossa, then restart once."
            )
        case .microphone where !store.permissions.microphone.isReady:
            MenuBarPermission(
                title: "Microphone access",
                detail: "Allow microphone access to use the fallback source."
            )
        case .systemAudio, .microphone, .preview:
            nil
        }
    }

    private func requestActivePermission() {
        switch store.captureMode {
        case .systemAudio:
            Task { await store.requestScreenRecordingPermission() }
        case .microphone:
            Task { await store.requestMicrophonePermission() }
        case .preview:
            break
        }
    }
}
