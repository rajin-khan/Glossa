import SwiftUI

struct SubtitleOverlayView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        Group {
            if let segment = store.currentSubtitle {
                subtitle(segment)
                    .id(segment.id)
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            } else {
                listeningPlaceholder
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .background(.black.opacity(0.30), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.white.opacity(0.14))
        }
        .shadow(color: .black.opacity(0.34), radius: 24, y: 10)
        .padding(12)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.18), value: store.currentSubtitle?.id)
    }

    private func subtitle(_ segment: TranscriptSegment) -> some View {
        VStack(spacing: 7) {
            Text(segment.translatedText)
                .font(.system(size: store.overlayTextSize.fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.72)

            if store.showsSourceText, segment.sourceText != segment.translatedText {
                Text(segment.sourceText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
        }
    }

    private var listeningPlaceholder: some View {
        HStack(spacing: 11) {
            BirdRibbonMarkView(size: 20)
                .opacity(store.isListening ? 0.82 : 0.56)

            Text(store.isListening ? "Listening for speech…" : "Subtitles are ready")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))
        }
    }
}
