import Foundation

@MainActor
final class TranslationRequestBroker: ObservableObject {
    @Published private(set) var currentRequest: TranslationRequest?
    @Published private(set) var status: TranslationStatus = .idle

    private var queue: [TranslationRequest] = []
    private var resultHandler: (@MainActor @Sendable (TranscriptSegment) -> Void)?

    func setResultHandler(_ handler: (@MainActor @Sendable (TranscriptSegment) -> Void)?) {
        resultHandler = handler
    }

    func submit(event: TranscriptionEvent, targetLanguage: TranslationLanguage) {
        let normalizedSource = event.sourceLanguage.lowercased()
        if normalizedSource == targetLanguage.code.lowercased() {
            resultHandler?(
                TranscriptSegment(
                    sourceText: event.text,
                    translatedText: event.text,
                    sourceLanguage: event.sourceLanguage,
                    isFinal: event.isFinal
                )
            )
            return
        }

        queue.append(
            TranslationRequest(
                sourceText: event.text,
                sourceLanguage: event.sourceLanguage,
                targetLanguageCode: targetLanguage.code,
                targetLanguageName: targetLanguage.name,
                isFinal: event.isFinal
            )
        )
        advanceIfNeeded()
    }

    func markPreparing(requestID: UUID) {
        guard currentRequest?.id == requestID,
              let currentRequest
        else {
            return
        }
        status = .preparing(target: currentRequest.targetLanguageName)
    }

    func markTranslating(requestID: UUID) {
        guard currentRequest?.id == requestID,
              let currentRequest
        else {
            return
        }
        status = .translating(target: currentRequest.targetLanguageName)
    }

    func complete(requestID: UUID, translatedText: String) {
        guard let request = currentRequest, request.id == requestID else { return }

        resultHandler?(
            TranscriptSegment(
                sourceText: request.sourceText,
                translatedText: translatedText,
                sourceLanguage: request.sourceLanguage,
                isFinal: request.isFinal
            )
        )
        GlossaLog.translation.info(
            "Completed translation target=\(request.targetLanguageCode, privacy: .public) characters=\(translatedText.count, privacy: .public)"
        )
        currentRequest = nil
        status = .ready
        advanceIfNeeded()
    }

    func fail(requestID: UUID, message: String) {
        guard let request = currentRequest, request.id == requestID else { return }

        resultHandler?(
            TranscriptSegment(
                sourceText: request.sourceText,
                translatedText: request.sourceText,
                sourceLanguage: request.sourceLanguage,
                isFinal: request.isFinal
            )
        )
        currentRequest = nil
        status = .failed(message)
        GlossaLog.translation.error("Translation failed: \(message, privacy: .public)")
        advanceIfNeeded()
    }

    func markUnavailable(_ message: String) {
        status = .unavailable(message)
    }

    func reset() {
        queue.removeAll()
        currentRequest = nil
        status = .idle
    }

    private func advanceIfNeeded() {
        guard currentRequest == nil, !queue.isEmpty else { return }
        currentRequest = queue.removeFirst()
    }
}
