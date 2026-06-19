import Foundation

enum ListeningState: Equatable {
    case idle
    case starting
    case listening
    case previewing
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "Ready"
        case .starting:
            "Starting"
        case .listening:
            "Listening"
        case .previewing:
            "Previewing"
        case .failed:
            "Needs Attention"
        }
    }

    var detail: String {
        switch self {
        case .idle:
            "Choose a target language and start Glossa when audio begins."
        case .starting:
            "Preparing the capture pipeline."
        case .listening:
            "System audio capture is active. Transcription will plug into this stream next."
        case .previewing:
            "Showing a sample subtitle flow so we can tune the overlay."
        case .failed(let message):
            message
        }
    }
}
