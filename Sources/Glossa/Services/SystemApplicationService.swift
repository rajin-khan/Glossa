import AppKit

@MainActor
protocol SystemApplicationServing: AnyObject {
    func openSystemAudioPermissionSettings()
    func openMicrophonePermissionSettings()
    func restartApplication()
}

@MainActor
final class SystemApplicationService: SystemApplicationServing {
    func openSystemAudioPermissionSettings() {
        openSystemSettingsPane([
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture"
        ])
    }

    func openMicrophonePermissionSettings() {
        openSystemSettingsPane([
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone"
        ])
    }

    func restartApplication() {
        let bundleURL = Bundle.main.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        GlossaLog.app.info("Restarting Glossa for refreshed privacy permissions")

        NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { _, error in
            if let error {
                GlossaLog.app.error("Restart failed: \(error.localizedDescription, privacy: .public)")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.terminate(nil)
        }
    }

    private func openSystemSettingsPane(_ candidates: [String]) {
        for candidate in candidates {
            guard let url = URL(string: candidate) else { continue }
            if NSWorkspace.shared.open(url) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    Self.activateSystemSettings()
                }
                return
            }
        }

        Self.activateSystemSettings()
    }

    private static func activateSystemSettings() {
        let bundleIdentifiers = [
            "com.apple.systempreferences",
            "com.apple.Preferences"
        ]

        if let runningApp = bundleIdentifiers
            .compactMap({ NSRunningApplication.runningApplications(withBundleIdentifier: $0).first })
            .first {
            runningApp.activate(options: [.activateAllWindows])
            return
        }

        guard let appURL = bundleIdentifiers
            .compactMap({ NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) })
            .first else { return }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
            if let error {
                GlossaLog.app.error("System Settings open failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
