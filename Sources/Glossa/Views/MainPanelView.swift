import SwiftUI

struct MainPanelView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusPanel
                    permissionPanel
                    languagePanel
                    subtitlePreview
                    transcriptList
                }
                .padding(28)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    store.clearTranscript()
                } label: {
                    Label("Clear", systemImage: "trash")
                }

                Button {
                    store.toggleListening()
                } label: {
                    Label(store.isListening ? "Pause" : "Start", systemImage: store.isListening ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "captions.bubble.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.teal)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Glossa")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                    Text("Live translated subtitles for whatever your Mac is playing.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ListeningBadge(state: store.listeningState)
            }
        }
        .padding(28)
        .background(.thinMaterial)
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(store.listeningState.label)
                .font(.title2.weight(.semibold))
            Text(store.listeningState.detail)
                .foregroundStyle(.secondary)
            Text(store.captureMode.subtitle)
                .font(.callout)
                .foregroundStyle(.tertiary)
            AudioLevelMeter(metrics: store.captureMetrics)
            PipelineStatsView(stats: store.pipelineStats)
            TranscriptionStatusView(status: store.transcriptionStatus)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
    }

    private var languagePanel: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Target Language")
                    .font(.headline)
                Text("Glossa auto-detects the source language and translates into this.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("Target Language", selection: $store.targetLanguage) {
                ForEach(TranslationLanguage.supported) { language in
                    Text("\(language.name) · \(language.nativeName)").tag(language)
                }
            }
            .labelsHidden()
            .frame(width: 230)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var permissionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Permissions")
                        .font(.headline)
                    Text("Glossa needs capture access before it can listen to system audio.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Refresh") {
                    Task { await store.refreshPermissions() }
                }
            }

            PermissionRow(
                title: "System Audio",
                detail: "Uses macOS Screen Recording permission for ScreenCaptureKit audio.",
                state: store.permissions.screenRecording,
                actionTitle: "Request"
            ) {
                Task { await store.requestScreenRecordingPermission() }
            }

            PermissionRow(
                title: "Microphone Fallback",
                detail: "Used only when you switch capture mode to Microphone.",
                state: store.permissions.microphone,
                actionTitle: "Request"
            ) {
                Task { await store.requestMicrophonePermission() }
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var subtitlePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subtitle Overlay")
                .font(.headline)

            SubtitleCard(segment: store.currentSubtitle)
                .frame(maxWidth: .infinity)
        }
    }

    private var transcriptList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Lines")
                .font(.headline)

            ForEach(store.recentSegments.reversed()) { segment in
                TranscriptRow(segment: segment)
            }
        }
    }
}
