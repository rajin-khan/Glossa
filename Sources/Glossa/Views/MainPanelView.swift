import SwiftUI

struct MainPanelView: View {
    @ObservedObject var store: GlossaStore
    @State private var showsDiagnostics = false

    var body: some View {
        ZStack {
            mainBackground

            VStack(spacing: 0) {
                MainPanelHeader(listeningState: store.listeningState)
                SessionControls(
                    captureMode: $store.captureMode,
                    targetLanguage: $store.targetLanguage,
                    availableLanguages: store.availableTargetLanguages,
                    isListening: store.isListening,
                    toggleListening: toggleListening
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        if needsActivePermission {
                            CapturePermissionBanner(
                                captureMode: store.captureMode,
                                restartApplication: store.restartApplication,
                                grantAccess: grantActivePermission
                            )
                        }

                        if let runtimeIssue {
                            RuntimeIssueBanner(issue: runtimeIssue)
                        }

                        if showsModelSetup {
                            ModelSetupBanner(
                                status: store.localModelStatus,
                                prepare: store.prepareLocalModel
                            )
                        }

                        LiveSubtitleSurface(store: store)
                        RecentTranscriptSection(segments: store.recentSegments)
                        DiagnosticsSection(
                            isExpanded: $showsDiagnostics,
                            captureMetrics: store.captureMetrics,
                            pipelineStats: store.pipelineStats,
                            transcriptionStatus: store.transcriptionStatus,
                            translationStatus: store.translationBroker.status
                        )
                    }
                    .padding(24)
                    .frame(maxWidth: 940)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Glossa")
        .toolbar {
            MainPanelToolbar(
                overlayVisible: store.overlayVisible,
                toggleOverlay: toggleOverlay
            )
        }
    }

    private var mainBackground: some View {
        ZStack {
            Color.glossaInk.ignoresSafeArea()
            LinearGradient(
                colors: [.white.opacity(0.08), .clear, .black.opacity(0.48)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GlossaMarkView(size: 460)
                .opacity(0.035)
                .rotationEffect(.degrees(-8))
                .offset(x: 245, y: 130)
        }
    }

    private var needsActivePermission: Bool {
        switch store.captureMode {
        case .systemAudio:
            !store.permissions.screenRecording.isReady
        case .microphone:
            !store.permissions.microphone.isReady
        case .preview:
            false
        }
    }

    private var showsModelSetup: Bool {
        guard store.transcriptionProvider == .whisperKit else { return false }
        return switch store.localModelStatus {
        case .notPrepared, .downloading, .loading:
            true
        case .downloaded, .ready, .unavailable, .failed:
            false
        }
    }

    private var runtimeIssue: RuntimeIssue? {
        if case .failed(let message) = store.listeningState {
            return RuntimeIssue(
                title: "Listening stopped",
                detail: message,
                actionTitle: "Try Again",
                action: store.startListening
            )
        }

        if case .failed(let message) = store.localModelStatus {
            return RuntimeIssue(
                title: "Speech model needs attention",
                detail: message,
                actionTitle: "Try Again",
                action: store.prepareLocalModel
            )
        }

        if case .failed(let message) = store.transcriptionStatus {
            return RuntimeIssue(
                title: "Transcription stopped",
                detail: message,
                actionTitle: "Restart",
                action: store.startListening
            )
        }

        switch store.translationBroker.status {
        case .failed(let message), .unavailable(let message):
            return RuntimeIssue(
                title: "Translation unavailable",
                detail: message,
                actionTitle: nil,
                action: nil
            )
        case .idle, .preparing, .ready, .translating:
            return nil
        }
    }

    private func toggleListening() {
        withAnimation(.snappy(duration: 0.18)) {
            store.toggleListening()
        }
    }

    private func toggleOverlay() {
        withAnimation(.snappy(duration: 0.18)) {
            store.toggleOverlay()
        }
    }

    private func grantActivePermission() {
        switch store.captureMode {
        case .systemAudio:
            store.openSystemAudioPermissionSettings()
            Task { await store.requestScreenRecordingPermission() }
        case .microphone:
            store.openMicrophonePermissionSettings()
            Task { await store.requestMicrophonePermission() }
        case .preview:
            break
        }
    }
}
