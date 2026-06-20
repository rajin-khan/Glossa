import SwiftUI

struct SubtitleOverlayView: View {
    @ObservedObject var store: GlossaStore
    @State private var displayedSegment: TranscriptSegment?
    @State private var isCaptionVisible = false
    @State private var contentTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            if let segment = displayedSegment {
                subtitle(segment)
                    .id(segment.id)
                    .opacity(isCaptionVisible ? 1 : 0)
                    .scaleEffect(isCaptionVisible ? 1 : 0.985)
            } else {
                listeningPlaceholder
                    .opacity(store.currentSubtitle == nil ? 1 : 0)
                    .scaleEffect(store.currentSubtitle == nil ? 1 : 0.94)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        .background(.black.opacity(store.overlayMetrics.backgroundOpacity), in: RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(.white.opacity(0.12))
        }
        .padding(8)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.20), value: isCaptionVisible)
        .animation(.easeInOut(duration: 0.24), value: displayedSegment?.id)
        .animation(.easeInOut(duration: 0.36), value: store.overlayScale)
        .onAppear {
            synchronizeContent(to: store.currentSubtitle, animated: false)
        }
        .onChange(of: store.currentSubtitle?.id) { _, _ in
            synchronizeContent(to: store.currentSubtitle, animated: true)
        }
        .onDisappear {
            contentTask?.cancel()
        }
    }

    private func subtitle(_ segment: TranscriptSegment) -> some View {
        VStack(spacing: sourceSpacing) {
            Text(segment.translatedText)
                .font(.system(size: store.overlayMetrics.primaryFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            if store.showsSourceText, segment.sourceText != segment.translatedText {
                Text(segment.sourceText)
                    .font(.system(size: store.overlayMetrics.sourceFontSize, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
        }
    }

    private var listeningPlaceholder: some View {
        ShimmeringOverlayMark(size: store.overlayMetrics.emptyMarkSize)
    }

    private var horizontalPadding: CGFloat {
        store.currentSubtitle == nil ? 8 : store.overlayMetrics.horizontalPadding
    }

    private var verticalPadding: CGFloat {
        store.currentSubtitle == nil ? 8 : store.overlayMetrics.verticalPadding
    }

    private var sourceSpacing: CGFloat {
        CGFloat(4 + store.overlayScale * 4)
    }

    private var cornerRadius: CGFloat {
        store.currentSubtitle == nil ? 999 : store.overlayMetrics.cornerRadius
    }

    private func synchronizeContent(to segment: TranscriptSegment?, animated: Bool) {
        contentTask?.cancel()

        guard animated else {
            displayedSegment = segment
            isCaptionVisible = segment != nil
            return
        }

        if let segment {
            contentTask = Task {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isCaptionVisible = false
                    }
                }

                try? await Task.sleep(for: .milliseconds(170))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    displayedSegment = segment
                }

                try? await Task.sleep(for: .milliseconds(180))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.20)) {
                        isCaptionVisible = true
                    }
                }
            }
        } else {
            contentTask = Task {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isCaptionVisible = false
                    }
                }

                try? await Task.sleep(for: .milliseconds(170))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    displayedSegment = nil
                }
            }
        }
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
            withAnimation(.linear(duration: 2.15).repeatForever(autoreverses: false)) {
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
