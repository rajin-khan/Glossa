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
                    nextConfiguration.source = nil
                    nextConfiguration.target = Locale.Language(identifier: request.targetLanguageCode)
                    nextConfiguration.invalidate()
                    configuration = nextConfiguration
                } else {
                    configuration = TranslationSession.Configuration(
                        source: nil,
                        target: Locale.Language(identifier: request.targetLanguageCode)
                    )
                }
            }
            .translationTask(configuration) { session in
                guard let request = broker.currentRequest else { return }

                do {
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
}
#endif
