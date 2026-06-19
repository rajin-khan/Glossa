import Foundation

enum TranscriptionProviderKind: String, CaseIterable, Identifiable {
    case debug = "Debug"
    case whisperKit = "WhisperKit Local"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .debug:
            "Local diagnostic provider that confirms audio chunks reach the ASR boundary."
        case .whisperKit:
            "Runs multilingual Whisper transcription entirely on this Mac."
        }
    }
}
