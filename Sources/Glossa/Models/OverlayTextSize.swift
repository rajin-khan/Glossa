import Foundation

enum OverlayTextSize: String, CaseIterable, Identifiable {
    case compact
    case standard
    case large

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact:
            "Compact"
        case .standard:
            "Standard"
        case .large:
            "Large"
        }
    }

    var fontSize: Double {
        switch self {
        case .compact:
            18
        case .standard:
            29
        case .large:
            34
        }
    }

    var panelBaseHeight: CGFloat {
        switch self {
        case .compact:
            72
        case .standard:
            126
        case .large:
            158
        }
    }

    var defaultWidthFraction: Double {
        switch self {
        case .compact:
            0.34
        case .standard:
            0.66
        case .large:
            0.76
        }
    }
}
