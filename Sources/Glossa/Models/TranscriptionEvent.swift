import Foundation

struct TranscriptionEvent: Sendable {
    var text: String
    var sourceLanguage: String
    var isFinal: Bool
}
