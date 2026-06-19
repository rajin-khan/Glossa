import Foundation

struct TranslationRequest: Identifiable, Equatable, Sendable {
    let id: UUID
    let sourceText: String
    let sourceLanguage: String
    let targetLanguageCode: String
    let targetLanguageName: String
    let isFinal: Bool

    init(
        id: UUID = UUID(),
        sourceText: String,
        sourceLanguage: String,
        targetLanguageCode: String,
        targetLanguageName: String,
        isFinal: Bool
    ) {
        self.id = id
        self.sourceText = sourceText
        self.sourceLanguage = sourceLanguage
        self.targetLanguageCode = targetLanguageCode
        self.targetLanguageName = targetLanguageName
        self.isFinal = isFinal
    }
}
