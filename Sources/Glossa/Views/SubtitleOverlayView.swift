import SwiftUI

struct SubtitleOverlayView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        Group {
            if let segment = store.currentSubtitle {
                subtitle(segment)
                    .id(segment.id)
                    .transition(.opacity.combined(with: .scale(scale: 0.982)))
            } else {
                listeningPlaceholder
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: store.overlayCornerRadius))
        .background(.black.opacity(store.overlayBackgroundOpacity), in: RoundedRectangle(cornerRadius: store.overlayCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: store.overlayCornerRadius)
                .strokeBorder(.white.opacity(0.12))
        }
        .shadow(color: .black.opacity(0.34), radius: 20, y: 8)
        .padding(8)
        .preferredColorScheme(.dark)
        .animation(.snappy(duration: 0.2), value: store.currentSubtitle?.id)
        .animation(.snappy(duration: 0.18), value: store.overlayFontSize)
        .animation(.snappy(duration: 0.18), value: store.overlayBackgroundOpacity)
    }

    private func subtitle(_ segment: TranscriptSegment) -> some View {
        VStack(spacing: sourceSpacing) {
            Text(segment.translatedText)
                .font(.system(size: store.overlayFontSize, weight: .semibold, design: store.overlayFontStyle.design))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.72)

            if store.showsSourceText, segment.sourceText != segment.translatedText {
                Text(segment.sourceText)
                    .font(.system(size: max(12, store.overlayFontSize * 0.48), weight: .medium, design: store.overlayFontStyle.design))
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
        }
    }

    private var listeningPlaceholder: some View {
        HStack(spacing: 11) {
            GlossaMarkView(size: 24)
                .opacity(store.isListening ? 0.82 : 0.56)

            Text(store.isListening ? "Listening for speech…" : "Subtitles are ready")
                .font(.system(size: max(11, store.overlayFontSize * 0.58), weight: .medium, design: store.overlayFontStyle.design))
                .foregroundStyle(.white.opacity(0.82))
        }
    }

    private var horizontalPadding: CGFloat {
        switch store.overlayTextSize {
        case .compact:
            14
        case .standard:
            28
        case .large:
            34
        }
    }

    private var verticalPadding: CGFloat {
        switch store.overlayTextSize {
        case .compact:
            8
        case .standard:
            17
        case .large:
            22
        }
    }

    private var sourceSpacing: CGFloat {
        store.overlayTextSize == .compact ? 4 : 7
    }
}
