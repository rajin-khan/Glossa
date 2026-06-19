import SwiftUI

struct ListeningBadge: View {
    let state: ListeningState

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(state.label)
                .font(.callout.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: Capsule())
    }

    private var color: Color {
        switch state {
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
}

struct SubtitleCard: View {
    let segment: TranscriptSegment?

    var body: some View {
        VStack(spacing: 8) {
            Text(segment?.translatedText ?? "Subtitles will appear here.")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.72)

            HStack(spacing: 8) {
                Text(segment?.sourceLanguage ?? "Auto")
                Text("→")
                Text(segment?.isFinal == true ? "Final" : "Live")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.white.opacity(0.18))
        }
        .shadow(color: .black.opacity(0.16), radius: 22, y: 12)
        .opacity(segment?.isFinal == false ? 0.82 : 1)
    }
}

struct TranscriptRow: View {
    let segment: TranscriptSegment
    var showsTimestamp = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(segment.translatedText)
                .font(.body.weight(.medium))
            Text(segment.sourceText)
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Text(segment.sourceLanguage)
                Spacer()
                if showsTimestamp {
                    Text(segment.createdAt, style: .time)
                }
                Text(segment.isFinal ? "Final" : "Live")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AudioLevelMeter: View {
    let metrics: AudioCaptureMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Input Level")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(detailText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.secondary.opacity(0.16))
                    Capsule()
                        .fill(.teal)
                        .frame(width: max(6, proxy.size.width * CGFloat(clamped(metrics.level))))
                    Capsule()
                        .fill(.white.opacity(0.72))
                        .frame(width: 2)
                        .offset(x: max(0, proxy.size.width * CGFloat(clamped(metrics.peak)) - 1))
                }
            }
            .frame(height: 10)
        }
    }

    private var detailText: String {
        guard metrics.lastUpdated != nil else { return "no signal" }
        let rate = metrics.sampleRate > 0 ? "\(Int(metrics.sampleRate / 1_000)) kHz" : "--"
        return "\(Int(metrics.level * 100))% · \(rate) · \(metrics.channelCount) ch"
    }

    private func clamped(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

struct PermissionRow: View {
    let title: String
    let detail: String
    let state: CapturePermissionState
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(state.label)
                .font(.caption.weight(.medium))
                .foregroundStyle(color)

            Button(actionTitle, action: action)
                .disabled(state.isReady)
        }
        .padding(12)
        .background(.quaternary.opacity(0.32), in: RoundedRectangle(cornerRadius: 8))
    }

    private var icon: String {
        switch state {
        case .granted:
            "checkmark.circle.fill"
        case .needsPermission:
            "exclamationmark.circle.fill"
        case .denied:
            "xmark.circle.fill"
        case .unknown:
            "questionmark.circle.fill"
        }
    }

    private var color: Color {
        switch state {
        case .granted:
            .teal
        case .needsPermission:
            .yellow
        case .denied:
            .red
        case .unknown:
            .secondary
        }
    }
}

struct PipelineStatsView: View {
    let stats: SubtitlePipelineStats

    var body: some View {
        HStack(spacing: 12) {
            Label("Pipeline", systemImage: "waveform.path")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()

            Text(detailText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
    }

    private var detailText: String {
        guard stats.lastUpdated != nil else {
            return "waiting for frames"
        }

        let speech = stats.isSpeechActive ? "speech" : "quiet"
        return "\(stats.receivedFrameCount) frames · \(stats.emittedChunkCount) chunks · \(stats.bufferedAudioDuration.formatted(.number.precision(.fractionLength(1))))s · \(speech)"
    }
}

struct TranscriptionStatusView: View {
    let status: TranscriptionStatus

    var body: some View {
        HStack(spacing: 12) {
            Label("Transcription", systemImage: "text.bubble")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()

            Text(status.label)
                .font(.caption.monospacedDigit())
                .foregroundStyle(color)
        }
    }

    private var color: Color {
        switch status {
        case .idle, .stopped:
            .secondary.opacity(0.72)
        case .loading:
            .yellow
        case .ready, .receiving:
            .teal
        case .failed:
            .red
        }
    }
}

struct TranslationStatusView: View {
    let status: TranslationStatus

    var body: some View {
        HStack(spacing: 12) {
            Label("Translation", systemImage: "character.book.closed")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()

            Text(status.label)
                .font(.caption.monospacedDigit())
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }

    private var color: Color {
        switch status {
        case .idle, .unavailable:
            .secondary.opacity(0.72)
        case .preparing:
            .yellow
        case .ready, .translating:
            .teal
        case .failed:
            .red
        }
    }
}

struct LocalModelPreparationView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Local Speech Model", systemImage: "cpu")
                    .font(.callout.weight(.semibold))
                Spacer()
                Text(store.localModelStatus.label)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
            }

            if let progress = store.localModelStatus.progress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
            }

            HStack {
                Text("The tiny multilingual model is downloaded once and runs entirely on this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Prepare Model") {
                    store.prepareLocalModel()
                }
                .disabled(!store.localModelStatus.canPrepare)
            }
        }
        .padding(.vertical, 6)
    }

    private var statusColor: Color {
        switch store.localModelStatus {
        case .notPrepared, .downloaded, .unavailable:
            .secondary
        case .downloading, .loading:
            .yellow
        case .ready:
            .teal
        case .failed:
            .red
        }
    }
}
