import SwiftUI

extension CaptureMode {
    var systemImage: String {
        switch self {
        case .systemAudio:
            "speaker.wave.2"
        case .microphone:
            "mic"
        case .preview:
            "play.rectangle"
        }
    }
}

extension ListeningState {
    var compactLabel: String {
        switch self {
        case .idle:
            "Ready"
        case .starting:
            "Starting"
        case .listening:
            "Live"
        case .previewing:
            "Preview"
        case .failed:
            "Issue"
        }
    }

    var statusColor: Color {
        switch self {
        case .idle:
            .secondary
        case .starting:
            .yellow
        case .listening, .previewing:
            .teal
        case .failed:
            .red
        }
    }

    var menuDetail: String {
        switch self {
        case .idle:
            "Ready"
        case .starting:
            "Preparing speech"
        case .listening:
            "Listening"
        case .previewing:
            "Previewing"
        case .failed:
            "Needs attention"
        }
    }
}

