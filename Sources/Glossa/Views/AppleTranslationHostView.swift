import SwiftUI

#if canImport(Translation)
@preconcurrency import Translation

@available(macOS 15.0, *)
struct AppleTranslationHostView: View {
    @ObservedObject var broker: TranslationRequestBroker
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityHidden(true)
            .onChange(of: broker.currentRequest, initial: true) { _, request in
                guard let request else { return }

                if var nextConfiguration = configuration {
                    nextConfiguration.source = sourceLanguage(for: request)
                    nextConfiguration.target = targetLanguage(for: request)
                    nextConfiguration.invalidate()
                    configuration = nextConfiguration
                } else {
                    configuration = makeConfiguration(for: request)
                }
            }
            .translationTask(configuration) { session in
                guard let request = broker.currentRequest else { return }

                do {
                    let target = targetLanguage(for: request)
                    let availability = LanguageAvailability()
                    let availabilityStatus: LanguageAvailability.Status

                    if let source = sourceLanguage(for: request) {
                        availabilityStatus = await availability.status(from: source, to: target)
                    } else {
                        availabilityStatus = try await availability.status(for: request.sourceText, to: target)
                    }

                    guard availabilityStatus != .unsupported else {
                        broker.fail(
                            requestID: request.id,
                            message: "\(request.targetLanguageName) is not supported by Apple Translation for this source on this Mac. Add a LibreTranslate endpoint in Settings for Bangla or other unsupported pairs."
                        )
                        return
                    }

                    broker.markPreparing(requestID: request.id)
                    try await session.prepareTranslation()
                    broker.markTranslating(requestID: request.id)
                    let response = try await session.translate(request.sourceText)
                    broker.complete(requestID: request.id, translatedText: response.targetText)
                } catch {
                    broker.fail(requestID: request.id, message: error.localizedDescription)
                }
            }
    }

    private func sourceLanguage(for request: TranslationRequest) -> Locale.Language? {
        let code = request.sourceLanguage.lowercased()
        guard (2...3).contains(code.count) else { return nil }
        return Locale.Language(identifier: code)
    }

    private func targetLanguage(for request: TranslationRequest) -> Locale.Language {
        Locale.Language(identifier: request.targetLanguageCode)
    }

    private func makeConfiguration(for request: TranslationRequest) -> TranslationSession.Configuration {
        let source = sourceLanguage(for: request)
        let target = targetLanguage(for: request)

        if #available(macOS 26.4, *) {
            return TranslationSession.Configuration(
                source: source,
                target: target,
                preferredStrategy: .lowLatency
            )
        }

        return TranslationSession.Configuration(source: source, target: target)
    }
}
#endif
