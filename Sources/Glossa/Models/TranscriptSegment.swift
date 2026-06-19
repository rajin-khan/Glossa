import Foundation

struct TranscriptSegment: Identifiable, Equatable {
    let id = UUID()
    var sourceText: String
    var translatedText: String
    var sourceLanguage: String
    var isFinal: Bool
    var createdAt: Date = .now
}
