import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: 28)
    private let popover = NSPopover()
    private var isInstalled = false

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
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 316, height: 408)
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
            NSApp.windows.first(where: \.canBecomeMain)?.makeKeyAndOrderFront(nil)
        }
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if !NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}
