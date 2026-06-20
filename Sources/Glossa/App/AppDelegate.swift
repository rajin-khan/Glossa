import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let overlayController = SubtitleOverlayController()
    private lazy var statusBarController = StatusBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        statusBarController.install()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func configure(store: GlossaStore) {
        overlayController.configure(store: store)
        store.setOverlayVisibilityHandler { [weak overlayController] isVisible in
            if isVisible {
                overlayController?.show()
            } else {
                overlayController?.hide()
            }
        }
        statusBarController.configure(store: store)
    }
}
