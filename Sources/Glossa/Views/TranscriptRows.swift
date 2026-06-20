import SwiftUI

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

struct EmptyTranscriptView: View {
    var body: some View {
        VStack(spacing: 12) {
            GlossaMarkView(size: 54)
                .opacity(0.42)
            Text("No captions yet")
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

