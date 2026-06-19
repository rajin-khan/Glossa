import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let overlayController = SubtitleOverlayController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @MainActor
    func configure(store: GlossaStore) {
        overlayController.configure(store: store)
    }
}
