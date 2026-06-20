import SwiftUI

struct LiveSubtitleSurface: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Label(store.captureMode.rawValue, systemImage: store.captureMode.systemImage)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(store.targetLanguage.nativeName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }

            Spacer(minLength: 8)

            ZStack {
                GlossaMarkView(size: 150)
                    .opacity(store.currentSubtitle == nil ? 0.10 : 0.045)
                    .rotationEffect(.degrees(-6))

                Text(translatedText)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.68)
                    .contentTransition(.opacity)
                    .id(store.currentSubtitle?.id)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            .animation(.easeInOut(duration: 0.24), value: store.currentSubtitle?.id)

            if let sourceText {
                Text(sourceText)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.58))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .transition(.opacity)
            }

            Spacer(minLength: 8)

            HStack(spacing: 7) {
                Circle()
                    .fill(store.listeningState.statusColor)
                    .frame(width: 7, height: 7)
                Text(flowStatus)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 285)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(.black.opacity(0.48))
                .overlay {
                    LinearGradient(
                        colors: [.white.opacity(0.08), .clear, .black.opacity(0.30)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.12))
        }
        .overlay(alignment: .bottomLeading) {
            Capsule()
                .fill(.white.opacity(0.18))
                .frame(width: store.isListening ? 150 : 70, height: 3)
                .padding(.leading, 24)
                .padding(.bottom, 16)
                .animation(.easeInOut(duration: 0.22), value: store.isListening)
        }
    }

    private var translatedText: String {
        guard let segment = store.currentSubtitle else { return "Ready when you are" }
        return segment.translatedText
    }

    private var sourceText: String? {
        guard store.showsSourceText,
              let segment = store.currentSubtitle,
              segment.sourceText != segment.translatedText
        else {
            return nil
        }
        return segment.sourceText
    }

    private var flowStatus: String {
        switch store.listeningState {
        case .idle:
            "Ready to listen"
        case .starting:
            "Preparing local models"
        case .listening:
            "Listening privately on this Mac"
        case .previewing:
            "Previewing subtitle motion"
        case .failed(let message):
            message
        }
    }
}

