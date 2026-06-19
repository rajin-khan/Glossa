import AppKit
import SwiftUI

@MainActor
final class SubtitleOverlayController {
    private weak var store: GlossaStore?
    private var panel: NSPanel?

    func configure(store: GlossaStore) {
        self.store = store
        if let panel {
            panel.contentView = NSHostingView(rootView: SubtitleOverlayView(store: store))
        }
    }

    func show() {
        guard let store else { return }

        if panel == nil {
            panel = makePanel(store: store)
        }

        panel?.orderFrontRegardless()
        store.overlayVisible = true
    }

    func hide() {
        panel?.orderOut(nil)
        store?.overlayVisible = false
    }

    func toggle() {
        if store?.overlayVisible == true {
            hide()
        } else {
            show()
        }
    }

    private func makePanel(store: GlossaStore) -> NSPanel {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let width: CGFloat = min(780, visibleFrame.width - 80)
        let rect = NSRect(
            x: visibleFrame.midX - width / 2,
            y: visibleFrame.minY + 72,
            width: width,
            height: 132
        )

        let panel = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.level = .floating
        panel.title = "Glossa Subtitles"
        panel.contentView = NSHostingView(rootView: SubtitleOverlayView(store: store))
        return panel
    }
}
