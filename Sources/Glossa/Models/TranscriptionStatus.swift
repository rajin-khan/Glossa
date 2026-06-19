import Foundation

enum TranscriptionStatus: Equatable, Sendable {
    case idle
    case ready(provider: String)
    case receiving(provider: String, chunkCount: Int)
    case stopped
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "ASR Idle"
        case .ready(let provider):
            "\(provider) Ready"
        case .receiving(let provider, let chunkCount):
            "\(provider) · \(chunkCount) chunks"
        case .stopped:
            "ASR Stopped"
        case .failed:
            "ASR Failed"
        }
    }
}
