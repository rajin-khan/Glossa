import SwiftUI

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

