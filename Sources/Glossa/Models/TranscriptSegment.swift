import Foundation

struct TranscriptSegment: Identifiable, Equatable, Sendable {
    let id = UUID()
    var sourceText: String
    var translatedText: String
    var sourceLanguage: String
    var isFinal: Bool
    var createdAt: Date = .now
}
