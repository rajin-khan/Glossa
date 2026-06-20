import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        Form {
            Section("Preview") {
                OverlayPreviewCard(store: store)
            }

            Section("Typography") {
                Toggle("Show original speech below translation", isOn: $store.showsSourceText)

                SliderRow(
                    title: "Overlay Scale",
                    value: $store.overlayScale,
                    range: OverlayLayoutMetrics.scaleRange,
                    step: 0.01,
                    valueLabel: scaleLabel
                )

                Text("Scale controls subtitle size, source text, padding, height, width, corners, and transparency together.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Floating Window") {
                LabeledContent("Visibility", value: store.overlayVisible ? "Shown" : "Hidden")

                HStack {
                    Button(store.overlayVisible ? "Hide Overlay" : "Show Overlay") {
                        store.toggleOverlay()
                    }

                    Button("Preview Motion") {
                        store.captureMode = .preview
                        if !store.isListening {
                            store.startListening()
                        }
                    }

                    Button("Reset Position") {
                        store.resetOverlayPosition()
                    }

                    Spacer()

                    Button("Reset Appearance") {
                        store.resetOverlayAppearance()
                    }
                }

                Text("Drag the subtitle window from its background. Reset Position returns it to the lower center.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 12)
    }

    private var scaleLabel: String {
        "\(Int(store.overlayScale * 100))% · \(Int(store.overlayMetrics.primaryFontSize)) pt"
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(valueLabel)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

private struct OverlayPreviewCard: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        VStack(spacing: 8) {
            Text("Audio stays on your Mac.")
                .font(.system(size: min(30, store.overlayMetrics.primaryFontSize), weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            if store.showsSourceText {
                Text("Le son reste sur votre Mac.")
                    .font(.system(size: min(18, store.overlayMetrics.sourceFontSize), weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
        .padding(.horizontal, store.overlayMetrics.horizontalPadding)
        .padding(.vertical, store.overlayMetrics.verticalPadding)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: store.overlayMetrics.cornerRadius))
        .background(.black.opacity(store.overlayMetrics.backgroundOpacity), in: RoundedRectangle(cornerRadius: store.overlayMetrics.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: store.overlayMetrics.cornerRadius)
                .strokeBorder(.white.opacity(0.12))
        }
        .preferredColorScheme(.dark)
    }
}
