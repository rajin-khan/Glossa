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
                        Label(mode.rawValue, systemImage: captureIcon(for: mode))
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
                HStack(spacing: 8) {
                    Text("Glossa")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                    GlossaMarkView(size: 28)
                        .opacity(0.72)
                }
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
            GlossaMarkView(size: 54)
                .opacity(0.42)
            Text("No Ribbon Yet")
                .font(.title3.weight(.semibold))
            Text("Translated lines will land here while Glossa listens.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.08))
        }
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
        .background(.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
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

            ZStack {
                GlossaMarkView(size: 150)
                    .opacity(store.currentSubtitle == nil ? 0.10 : 0.045)
                    .rotationEffect(.degrees(-6))

                Text(translatedText)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.68)
                    .contentTransition(.numericText())
            }

            if let sourceText {
                Text(sourceText)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.58))
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
        .frame(maxWidth: .infinity, minHeight: 285)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(.black.opacity(0.48))
                .overlay {
                    LinearGradient(
                        colors: [.white.opacity(0.08), .clear, .black.opacity(0.30)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.12))
        }
        .overlay(alignment: .bottomLeading) {
            Capsule()
                .fill(.white.opacity(0.18))
                .frame(width: store.isListening ? 150 : 70, height: 3)
                .padding(.leading, 24)
                .padding(.bottom, 16)
                .animation(.easeInOut(duration: 0.22), value: store.isListening)
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
