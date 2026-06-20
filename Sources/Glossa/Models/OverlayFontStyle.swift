import SwiftUI

enum OverlayFontStyle: String, CaseIterable, Identifiable {
    case rounded
    case system
    case serif
    case mono

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rounded:
            "Rounded"
        case .system:
            "System"
        case .serif:
            "Serif"
        case .mono:
            "Mono"
        }
    }

    var design: Font.Design {
        switch self {
        case .rounded:
            .rounded
        case .system:
            .default
        case .serif:
            .serif
        case .mono:
            .monospaced
        }
    }
}
