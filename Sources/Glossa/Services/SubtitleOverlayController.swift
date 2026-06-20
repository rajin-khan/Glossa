import AppKit
import SwiftUI

@MainActor
final class SubtitleOverlayController {
    private weak var store: GlossaStore?
    private var panel: NSPanel?

    func configure(store: GlossaStore) {
        self.store = store
        store.setOverlayAppearanceChangeHandler { [weak self] in
            self?.updateLayout(animated: true)
        }
        store.setOverlayPositionResetHandler { [weak self] in
            self?.resetPosition()
        }
        if let panel {
            panel.contentView = NSHostingView(rootView: SubtitleOverlayView(store: store))
            updateLayout(animated: false)
        }
        if store.overlayVisible {
            show()
        }
    }

    func show() {
        guard let store else { return }

        if panel == nil {
            panel = makePanel(store: store)
        }

        updateLayout(animated: false)
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
        let panel = NSPanel(
            contentRect: targetRect(for: store),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.animationBehavior = .utilityWindow
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.title = "Glossa Subtitles"
        panel.contentView = NSHostingView(rootView: SubtitleOverlayView(store: store))
        return panel
    }

    private func updateLayout(animated: Bool) {
        guard let store, let panel else { return }
        let rect = targetRect(for: store, resetPosition: false)
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(rect, display: true)
            }
        } else {
            panel.setFrame(rect, display: true)
        }
    }

    private func resetPosition() {
        guard let store else { return }
        if panel == nil {
            panel = makePanel(store: store)
        }
        guard let panel else { return }
        let rect = targetRect(for: store, resetPosition: true)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(rect, display: true)
        }
        panel.orderFrontRegardless()
    }

    private func targetRect(for store: GlossaStore, resetPosition: Bool = true) -> NSRect {
        let visibleFrame = panel?.screen?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let maxWidth = max(220, visibleFrame.width - 72)
        let width = min(maxWidth, max(220, visibleFrame.width * store.overlayWidthFraction))
        let sourceHeight = store.showsSourceText ? max(18, CGFloat(store.overlayFontSize * 0.70)) : 0
        let fontDelta = max(-14, CGFloat(store.overlayFontSize - store.overlayTextSize.fontSize) * 1.25)
        let height = max(54, store.overlayTextSize.panelBaseHeight + sourceHeight + fontDelta)
        let currentFrame = panel?.frame
        let proposedX = resetPosition ? (visibleFrame.midX - width / 2) : (currentFrame.map { $0.midX - width / 2 } ?? (visibleFrame.midX - width / 2))
        let proposedY = resetPosition ? (visibleFrame.minY + 58) : (currentFrame?.minY ?? (visibleFrame.minY + 58))
        let x = min(max(visibleFrame.minX + 18, proposedX), visibleFrame.maxX - width - 18)
        let y = min(max(visibleFrame.minY + 18, proposedY), visibleFrame.maxY - height - 18)

        return NSRect(x: x, y: y, width: width, height: height)
    }
}
