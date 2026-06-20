import SwiftUI

struct OnboardingView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var store: GlossaStore
    let finish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            HStack(alignment: .top, spacing: 12) {
                setupCard(
                    icon: "lock.shield",
                    title: "Grant capture access",
                    detail: "System audio uses Screen & System Audio Recording. Microphone is only used when you choose it.",
                    actionTitle: "Open Permissions"
                ) {
                    store.openSystemAudioPermissionSettings()
                }

                setupCard(
                    icon: "cpu",
                    title: "Prepare local speech",
                    detail: "The free tiny multilingual model downloads once, then runs on this Mac.",
                    actionTitle: store.localModelStatus.preparationActionTitle
                ) {
                    store.prepareLocalModel()
                }
                .disabled(!store.localModelStatus.canPrepare)

                setupCard(
                    icon: "captions.bubble",
                    title: "Start listening",
                    detail: "Pick a target language, then use system audio, microphone, or preview mode.",
                    actionTitle: "Start Preview"
                ) {
                    store.captureMode = .preview
                    if !store.isListening {
                        store.startListening()
                    }
                }
            }

            Divider()
                .overlay(.white.opacity(0.14))

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You can reopen this from Help -> Show Glossa Onboarding.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Glossa never needs an OpenAI key for the local-first path.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Done", action: finish)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .padding(28)
        .frame(width: 720)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await store.refreshPermissions() }
        }
        .background {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.11, blue: 0.12),
                    Color(red: 0.04, green: 0.05, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            GlossaMarkView(size: 52)
                .padding(10)
                .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 5) {
                Text("Set up Glossa")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                Text("Private captions for Mac audio, ready in a few small steps.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func setupCard(
        icon: String,
        title: String,
        detail: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.cyan)
                .frame(width: 36, height: 36)
                .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(actionTitle, action: action)
                .buttonStyle(.bordered)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.12))
        }
    }
}
