import SwiftUI

struct MainPanelView: View {
    @ObservedObject var store: GlossaStore
    @State private var showsDiagnostics = false

    var body: some View {
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

            VStack(spacing: 0) {
                brandHeader
                sessionControls

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        if needsActivePermission {
                            activePermissionBanner
                        }

                        if let runtimeIssue {
                            RuntimeIssueBanner(issue: runtimeIssue)
                        }

                        if showsModelSetup {
                            modelSetupBanner
                        }

                        LiveSubtitleSurface(store: store)
                        recentTranscript
                        diagnostics
                    }
                    .padding(24)
                    .frame(maxWidth: 940)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Glossa")
        .toolbar {
            ToolbarItemGroup {
            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    store.toggleOverlay()
                }
            } label: {
                Label(
                    store.overlayVisible ? "Hide Overlay" : "Show Overlay",
                        systemImage: store.overlayVisible ? "rectangle.slash" : "rectangle.on.rectangle"
                    )
                }
                .help(store.overlayVisible ? "Hide subtitle overlay" : "Show subtitle overlay")

            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            }
        }
    }

    private var sessionControls: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Listen To")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker("Capture", selection: $store.captureMode) {
                    ForEach(CaptureMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .frame(maxWidth: 340)

            VStack(alignment: .leading, spacing: 6) {
                Text("Translate Into")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker("Translate to", selection: $store.targetLanguage) {
                    ForEach(store.availableTargetLanguages) { language in
                        Text("\(language.name) · \(language.nativeName)")
                            .tag(language)
                    }
                }
            }
            .frame(width: 230)

            Spacer()

            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    store.toggleListening()
                }
            } label: {
                Label(
                    store.isListening ? "Pause" : "Start",
                    systemImage: store.isListening ? "pause.fill" : "play.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.space, modifiers: [])
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.black.opacity(0.32))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 16) {
            GlossaAppIconView(size: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text("Glossa")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                Text("Private captions for Mac audio.")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            ListeningBadge(state: store.listeningState)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                LinearGradient(
                    colors: [.white.opacity(0.08), .black.opacity(0.20)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
        }
    }

    private var recentTranscript: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent")
                    .font(.headline)
                Spacer()
                Text(lineCountLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if store.recentSegments.isEmpty {
                EmptyTranscriptView()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(store.recentSegments.suffix(4).reversed().enumerated()), id: \.element.id) { index, segment in
                        TranscriptRow(segment: segment)
                        if index < min(3, store.recentSegments.count - 1) {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var diagnostics: some View {
        DisclosureGroup("Diagnostics", isExpanded: $showsDiagnostics) {
            VStack(spacing: 10) {
                AudioLevelMeter(metrics: store.captureMetrics)
                PipelineStatsView(stats: store.pipelineStats)
                TranscriptionStatusView(status: store.transcriptionStatus)
                TranslationStatusView(status: store.translationBroker.status)
            }
            .padding(.top, 10)
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    private var lineCountLabel: String {
        let count = store.recentSegments.count
        return "\(count) \(count == 1 ? "line" : "lines")"
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

    private var activePermissionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                Text(permissionTitle)
                    .font(.callout.weight(.semibold))
                Text(permissionDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if store.captureMode == .systemAudio {
                Button("Restart Glossa") {
                    store.restartApplication()
                }
                .help("Apply a newly granted Screen & System Audio Recording permission")
            }

            Button("Grant Access") {
                if store.captureMode == .systemAudio {
                    store.openSystemAudioPermissionSettings()
                } else {
                    store.openMicrophonePermissionSettings()
                }
                Task {
                    if store.captureMode == .systemAudio {
                        await store.requestScreenRecordingPermission()
                    } else {
                        await store.requestMicrophonePermission()
                    }
                }
            }
        }
        .padding(14)
        .background(.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.yellow.opacity(0.24))
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

    private var modelSetupBanner: some View {
        HStack(spacing: 12) {
            GlossaMarkView(size: 28)
                .opacity(0.82)

            VStack(alignment: .leading, spacing: 4) {
                Text(modelSetupTitle)
                    .font(.callout.weight(.semibold))
                Text("Glossa uses a free multilingual speech model that stays on this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let progress = store.localModelStatus.progress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 260)
                }
            }

            Spacer()

            Button(store.localModelStatus.preparationActionTitle) {
                store.prepareLocalModel()
            }
            .disabled(!store.localModelStatus.canPrepare)
        }
        .padding(14)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.12))
        }
    }

    private var modelSetupTitle: String {
        switch store.localModelStatus {
        case .notPrepared:
            "One-time speech model setup"
        case .downloading:
            "Downloading speech model"
        case .loading:
            "Preparing speech model"
        case .downloaded, .ready, .unavailable, .failed:
            "Local speech model"
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

    private var permissionTitle: String {
        store.captureMode == .systemAudio ? "System audio access required" : "Microphone access required"
    }

    private var permissionDetail: String {
        store.captureMode == .systemAudio
            ? "Allow Glossa in Screen & System Audio Recording, then restart once."
            : "Allow microphone access to use the fallback capture source."
    }
}
