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
    }

    func hide() {
        panel?.orderOut(nil)
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
                context.duration = store.currentSubtitle == nil ? 0.28 : 0.34
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
            context.duration = 0.40
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(rect, display: true)
        }
        panel.orderFrontRegardless()
    }

    private func targetRect(for store: GlossaStore, resetPosition: Bool = true) -> NSRect {
        let visibleFrame = panel?.screen?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let metrics = overlayMetrics(for: store, visibleFrame: visibleFrame)
        let width = metrics.width
        let height = metrics.height
        let currentFrame = panel?.frame
        let proposedX = resetPosition ? (visibleFrame.midX - width / 2) : (currentFrame.map { $0.midX - width / 2 } ?? (visibleFrame.midX - width / 2))
        let proposedY = resetPosition ? (visibleFrame.minY + 58) : (currentFrame?.minY ?? (visibleFrame.minY + 58))
        let x = min(max(visibleFrame.minX + 18, proposedX), visibleFrame.maxX - width - 18)
        let y = min(max(visibleFrame.minY + 18, proposedY), visibleFrame.maxY - height - 18)

        return NSRect(x: x, y: y, width: width, height: height)
    }

    private func overlayMetrics(for store: GlossaStore, visibleFrame: NSRect) -> (width: CGFloat, height: CGFloat) {
        let screenMaxWidth = max(160, visibleFrame.width - 72)
        if store.currentSubtitle == nil {
            let side = CGFloat(48 + store.overlayScale * 24)
            return (side, side)
        }

        let layout = store.overlayMetrics
        let primaryFont = CGFloat(layout.primaryFontSize)
        let sourceFont = CGFloat(layout.sourceFontSize)
        let horizontalPadding = layout.horizontalPadding + 16
        let verticalPadding = layout.verticalPadding + 16
        let minWidth = CGFloat(190 + store.overlayScale * 80)
        let maxWidth = min(screenMaxWidth, max(minWidth, visibleFrame.width * min(0.84, 0.48 + store.overlayScale * 0.20)))
        let primaryText = store.currentSubtitle?.translatedText ?? ""
        let sourceText = sourceText(for: store)
        let longestLineEstimate = max(
            estimatedWidth(for: primaryText, fontSize: primaryFont),
            estimatedWidth(for: sourceText, fontSize: sourceFont)
        )
        let desiredWidth = longestLineEstimate + horizontalPadding * 2
        let width = min(maxWidth, max(minWidth, desiredWidth))
        let contentWidth = max(120, width - horizontalPadding * 2)
        let primaryLines = lineCount(for: primaryText, fontSize: primaryFont, contentWidth: contentWidth, limit: 2)
        let sourceLines = lineCount(for: sourceText, fontSize: sourceFont, contentWidth: contentWidth, limit: 2)
        let sourceSpacing = sourceText.isEmpty ? 0 : CGFloat(4 + store.overlayScale * 4)
        let textHeight =
            CGFloat(primaryLines) * primaryFont * 1.22
            + sourceSpacing
            + CGFloat(sourceLines) * sourceFont * 1.25
        let height = max(48, textHeight + verticalPadding * 2)

        return (width.rounded(.up), height.rounded(.up))
    }

    private func sourceText(for store: GlossaStore) -> String {
        guard store.showsSourceText,
              let segment = store.currentSubtitle,
              segment.sourceText != segment.translatedText
        else {
            return ""
        }
        return segment.sourceText
    }

    private func estimatedWidth(for text: String, fontSize: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let wideCharacters = text.filter { "MW@#%&".contains($0) }.count
        let narrowCharacters = text.filter { " il.,'’".contains($0) }.count
        let otherCharacters = max(0, text.count - wideCharacters - narrowCharacters)
        return CGFloat(wideCharacters) * fontSize * 0.78
            + CGFloat(narrowCharacters) * fontSize * 0.30
            + CGFloat(otherCharacters) * fontSize * 0.54
    }

    private func lineCount(for text: String, fontSize: CGFloat, contentWidth: CGFloat, limit: Int) -> Int {
        guard !text.isEmpty else { return 0 }
        let estimate = estimatedWidth(for: text, fontSize: fontSize)
        return min(limit, max(1, Int(ceil(estimate / max(1, contentWidth)))))
    }
}
