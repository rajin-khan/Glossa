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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        .background(.black.opacity(store.overlayComputedBackgroundOpacity), in: RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(.white.opacity(0.12))
        }
        .padding(8)
        .preferredColorScheme(.dark)
        .animation(.snappy(duration: 0.2), value: store.currentSubtitle?.id)
        .animation(.snappy(duration: 0.18), value: store.overlayScale)
    }

    private func subtitle(_ segment: TranscriptSegment) -> some View {
        VStack(spacing: sourceSpacing) {
            Text(segment.translatedText)
                .font(.system(size: store.overlayPrimaryFontSize, weight: .semibold, design: store.overlayFontStyle.design))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            if store.showsSourceText, segment.sourceText != segment.translatedText {
                Text(segment.sourceText)
                    .font(.system(size: store.overlaySourceFontSize, weight: .medium, design: store.overlayFontStyle.design))
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
        }
    }

    private var listeningPlaceholder: some View {
        ShimmeringOverlayMark(size: store.overlayEmptyMarkSize)
    }

    private var horizontalPadding: CGFloat {
        store.currentSubtitle == nil ? 8 : store.overlayHorizontalPadding
    }

    private var verticalPadding: CGFloat {
        store.currentSubtitle == nil ? 8 : store.overlayVerticalPadding
    }

    private var sourceSpacing: CGFloat {
        CGFloat(4 + store.overlayScale * 4)
    }

    private var cornerRadius: CGFloat {
        store.currentSubtitle == nil ? 999 : store.overlayComputedCornerRadius
    }
}

private struct ShimmeringOverlayMark: View {
    let size: CGFloat
    @State private var isLit = false

    var body: some View {
        GlossaMarkView(size: size)
            .opacity(isLit ? 0.86 : 0.44)
            .scaleEffect(isLit ? 1.04 : 0.96)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                    isLit = true
                }
            }
    }
}
