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
                Text(segment.isFinal ? "Final" : "Live")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.34), in: RoundedRectangle(cornerRadius: 8))
    }
}
