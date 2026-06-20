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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sheenPosition: CGFloat = -1

    var body: some View {
        ZStack {
            centeredMark
                .opacity(0.72)

            if !reduceMotion {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.08),
                                .white.opacity(0.92),
                                .white.opacity(0.12),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(8, size * 0.34), height: size * 2.4)
                    .rotationEffect(.degrees(28))
                    .offset(x: sheenPosition * size * 1.55)
                    .blendMode(.screen)
                    .mask(centeredMark)
            }
        }
        .frame(width: size, height: size)
        .drawingGroup(opaque: false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            sheenPosition = -1
            withAnimation(.linear(duration: 1.55).repeatForever(autoreverses: false)) {
                sheenPosition = 1
            }
        }
    }

    private var centeredMark: some View {
        GlossaMarkView(size: size)
            .frame(width: size, height: size, alignment: .center)
            .offset(x: max(2, size * 0.10))
    }
}
