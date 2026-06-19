import Foundation

enum WorkspaceSection: String, CaseIterable, Identifiable {
    case live = "Live"
    case transcript = "Transcript"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .live:
            "captions.bubble"
        case .transcript:
            "text.alignleft"
        }
    }
}
