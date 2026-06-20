import AppKit
import SwiftUI

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

    @MainActor
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

@MainActor
private final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: 28)
    private let popover = NSPopover()
    private weak var store: GlossaStore?
    private var isInstalled = false

    override init() {
        super.init()
    }

    func install() {
        guard !isInstalled else { return }
        isInstalled = true
        guard let button = statusItem.button else { return }

        if let image = GlossaBrandAssets.templateMarkImage() {
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = true
            button.image = image
            button.imageScaling = .scaleProportionallyDown
            button.imagePosition = .imageOnly
        } else {
            button.title = "G"
        }

        button.toolTip = "Glossa"
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    func configure(store: GlossaStore) {
        self.store = store
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 332, height: 440)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContent(
                store: store,
                openMain: { [weak self] in
                    self?.closePopover()
                    self?.openMainWindow()
                },
                openSettingsWindow: { [weak self] in
                    self?.closePopover()
                    self?.openSettings()
                }
            )
        )
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            closePopover()
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title == "Glossa" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            for window in NSApp.windows where window.canBecomeMain {
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if !NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}
