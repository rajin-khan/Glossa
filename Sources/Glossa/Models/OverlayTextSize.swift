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
            24
        case .standard:
            29
        case .large:
            34
        }
    }
}
