import SwiftUI

struct MainPanelView: View {
    @ObservedObject var store: GlossaStore
    @State private var showsDiagnostics = false

    var body: some View {
        VStack(spacing: 0) {
            brandHeader
            sessionControls
            Divider()

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
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Glossa")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    store.toggleOverlay()
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
        HStack(spacing: 14) {
            Picker("Capture", selection: $store.captureMode) {
                ForEach(CaptureMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: captureIcon(for: mode))
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 330)

            Divider()
                .frame(height: 22)

            Picker("Translate to", selection: $store.targetLanguage) {
                ForEach(store.availableTargetLanguages) { language in
                    Text("\(language.name) · \(language.nativeName)")
                        .tag(language)
                }
            }
            .frame(width: 210)

            Spacer()

            Button {
                store.toggleListening()
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
        .padding(.vertical, 14)
    }

    private var brandHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.72))
                BirdRibbonMarkView(size: 42)
            }
            .frame(width: 58, height: 58)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.white.opacity(0.10))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Glossa")
                    .font(.title2.weight(.semibold))
                Text("Carries live speech as a ribbon of translated captions.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ListeningBadge(state: store.listeningState)
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .background(.black.opacity(0.28))
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
        .background(.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
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
            Image(systemName: "cpu")
                .font(.title3)
                .foregroundStyle(.teal)

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
        .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
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

    private func captureIcon(for mode: CaptureMode) -> String {
        switch mode {
        case .systemAudio:
            "speaker.wave.2"
        case .microphone:
            "mic"
        case .preview:
            "play.rectangle"
        }
    }
}

private struct EmptyTranscriptView: View {
    var body: some View {
        VStack(spacing: 12) {
            BirdRibbonMarkView(size: 42)
                .opacity(0.42)
            Text("No Ribbon Yet")
                .font(.title3.weight(.semibold))
            Text("Translated lines will land here while Glossa listens.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }
}

private struct RuntimeIssue {
    let title: String
    let detail: String
    let actionTitle: String?
    let action: (() -> Void)?
}

private struct RuntimeIssueBanner: View {
    let issue: RuntimeIssue

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 3) {
                Text(issue.title)
                    .font(.callout.weight(.semibold))
                Text(issue.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()

            if let actionTitle = issue.actionTitle,
               let action = issue.action {
                Button(actionTitle, action: action)
            }
        }
        .padding(14)
        .background(.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.red.opacity(0.20))
        }
    }
}

private struct LiveSubtitleSurface: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Label(store.captureMode.rawValue, systemImage: captureIcon)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(store.targetLanguage.nativeName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }

            Spacer(minLength: 8)

            Text(translatedText)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.68)
                .contentTransition(.numericText())

            if let sourceText {
                Text(sourceText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            Spacer(minLength: 8)

            HStack(spacing: 7) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(flowStatus)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 260)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .background(.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.separator.opacity(0.45))
        }
    }

    private var translatedText: String {
        guard let segment = store.currentSubtitle else { return "Ready when you are" }
        return segment.translatedText
    }

    private var sourceText: String? {
        guard store.showsSourceText,
              let segment = store.currentSubtitle,
              segment.sourceText != segment.translatedText
        else {
            return nil
        }
        return segment.sourceText
    }

    private var flowStatus: String {
        switch store.listeningState {
        case .idle:
            "Ready to listen"
        case .starting:
            "Preparing local models"
        case .listening:
            "Listening privately on this Mac"
        case .previewing:
            "Previewing subtitle motion"
        case .failed(let message):
            message
        }
    }

    private var statusColor: Color {
        switch store.listeningState {
        case .idle:
            .secondary
        case .starting:
            .yellow
        case .listening, .previewing:
            .teal
        case .failed:
            .red
        }
    }

    private var captureIcon: String {
        switch store.captureMode {
        case .systemAudio:
            "speaker.wave.2"
        case .microphone:
            "mic"
        case .preview:
            "play.rectangle"
        }
    }
}
