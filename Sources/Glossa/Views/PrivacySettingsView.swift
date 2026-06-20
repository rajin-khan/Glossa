import SwiftUI

struct PrivacySettingsView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        Form {
            Section("Local by Default") {
                LabeledContent("Speech Recognition", value: "WhisperKit on this Mac")
                LabeledContent("Translation", value: "Apple first, fallback optional")
                LabeledContent("Audio Storage", value: "Never stored")
                LabeledContent("Account or API Key", value: "Not required")
            }

            Section("Capture Permissions") {
                settingsPermissionRow(
                    title: "System Audio",
                    state: store.permissions.screenRecording
                ) {
                    Task { await store.requestScreenRecordingPermission() }
                }

                settingsPermissionRow(
                    title: "Microphone",
                    state: store.permissions.microphone
                ) {
                    Task { await store.requestMicrophonePermission() }
                }

                HStack {
                    Button("Refresh") {
                        Task { await store.refreshPermissions() }
                    }
                    Spacer()
                    if !store.permissions.screenRecording.isReady {
                        Button("Restart Glossa") {
                            store.restartApplication()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 12)
    }

    private func settingsPermissionRow(
        title: String,
        state: CapturePermissionState,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            LabeledContent(title, value: state.label)
            if state.isReady {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.teal)
                    .accessibilityLabel("Ready")
            } else {
                Button("Grant Access", action: action)
            }
        }
    }
}
