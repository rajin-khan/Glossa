import Foundation

enum CaptureMode: String, CaseIterable, Identifiable {
    case systemAudio = "System Audio"
    case microphone = "Microphone"
    case preview = "Preview"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .systemAudio:
            "Capture media playing on this Mac."
        case .microphone:
            "Use the current input device as a fallback."
        case .preview:
            "Show sample translated subtitles without capturing audio."
        }
    }
}
