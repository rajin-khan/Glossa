import SwiftUI

struct RecentTranscriptSection: View {
    let segments: [TranscriptSegment]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent")
                    .font(.headline)
                Spacer()
                Text(lineCountLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if segments.isEmpty {
                EmptyTranscriptView()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(segments.suffix(4).reversed().enumerated()), id: \.element.id) { index, segment in
                        TranscriptRow(segment: segment)
                        if index < min(3, segments.count - 1) {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var lineCountLabel: String {
        "\(segments.count) \(segments.count == 1 ? "line" : "lines")"
    }
}

struct DiagnosticsSection: View {
    @Binding var isExpanded: Bool
    let captureMetrics: AudioCaptureMetrics
    let pipelineStats: SubtitlePipelineStats
    let transcriptionStatus: TranscriptionStatus
    let translationStatus: TranslationStatus

    var body: some View {
        DisclosureGroup("Diagnostics", isExpanded: $isExpanded) {
            VStack(spacing: 10) {
                AudioLevelMeter(metrics: captureMetrics)
                PipelineStatsView(stats: pipelineStats)
                TranscriptionStatusView(status: transcriptionStatus)
                TranslationStatusView(status: translationStatus)
            }
            .padding(.top, 10)
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }
}

struct CapturePermissionBanner: View {
    let captureMode: CaptureMode
    let restartApplication: () -> Void
    let grantAccess: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if captureMode == .systemAudio {
                Button("Restart Glossa", action: restartApplication)
                    .help("Apply a newly granted Screen & System Audio Recording permission")
            }

            Button("Grant Access", action: grantAccess)
                .buttonStyle(.borderedProminent)
        }
        .padding(14)
        .background(.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.yellow.opacity(0.24))
        }
    }

    private var title: String {
        captureMode == .systemAudio ? "System audio access required" : "Microphone access required"
    }

    private var detail: String {
        captureMode == .systemAudio
            ? "Allow Glossa in Screen & System Audio Recording, then restart once."
            : "Allow microphone access to use the fallback capture source."
    }
}

struct ModelSetupBanner: View {
    let status: LocalModelStatus
    let prepare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform.badge.magnifyingglass")
                .font(.title3)
                .foregroundStyle(.cyan)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text("Glossa uses a free multilingual speech model that stays on this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let progress = status.progress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 260)
                }
            }

            Spacer()

            Button(status.preparationActionTitle, action: prepare)
                .disabled(!status.canPrepare)
        }
        .padding(14)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.12))
        }
    }

    private var title: String {
        switch status {
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
}
