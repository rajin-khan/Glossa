import Foundation

struct OverlayLayoutMetrics {
    static let scaleRange = 0.20...1.35

    let scale: Double

    init(scale: Double) {
        self.scale = Self.clampedScale(scale)
    }

    var primaryFontSize: Double {
        (8 + scale * 21).rounded()
    }

    var sourceFontSize: Double {
        max(9, (primaryFontSize * 0.48).rounded())
    }

    var horizontalPadding: CGFloat {
        CGFloat(8 + scale * 20)
    }

    var verticalPadding: CGFloat {
        CGFloat(6 + scale * 12)
    }

    var cornerRadius: CGFloat {
        CGFloat(8 + scale * 18)
    }

    var backgroundOpacity: Double {
        min(0.64, max(0.06, 0.04 + scale * 0.44))
    }

    var emptyMarkSize: CGFloat {
        CGFloat(22 + scale * 18)
    }

    static func clampedScale(_ scale: Double) -> Double {
        min(scaleRange.upperBound, max(scaleRange.lowerBound, scale))
    }
}
