import Foundation

@MainActor
final class TranscriptionCoordinator {
    private var service: TranscriptionServing
    private var transcriptHandler: (@MainActor @Sendable (TranscriptionEvent) -> Void)?
    private var statusHandler: (@MainActor @Sendable (TranscriptionStatus) -> Void)?
    private var modelStatusHandler: (@MainActor @Sendable (LocalModelStatus) -> Void)?

    init(
        provider: TranscriptionProviderKind,
        service: TranscriptionServing? = nil
    ) {
        self.service = service ?? Self.makeService(for: provider)
    }

    func setTranscriptHandler(_ handler: (@MainActor @Sendable (TranscriptionEvent) -> Void)?) {
        transcriptHandler = handler
        service.setTranscriptHandler(handler)
    }

    func setStatusHandler(_ handler: (@MainActor @Sendable (TranscriptionStatus) -> Void)?) {
        statusHandler = handler
        service.setStatusHandler(handler)
    }

    func setModelStatusHandler(_ handler: (@MainActor @Sendable (LocalModelStatus) -> Void)?) {
        modelStatusHandler = handler
        attachModelStatusHandler()
    }

    func replaceService(for provider: TranscriptionProviderKind) {
        detachHandlers()
        _ = service.stop()
        service = Self.makeService(for: provider)
        attachHandlers()
    }

    func prepareModel() {
        guard let modelManager = service as? LocalModelManaging else {
            modelStatusHandler?(.unavailable)
            return
        }
        modelManager.prepareModel()
    }

    func start(targetLanguage: TranslationLanguage) -> TranscriptionStatus {
        service.start(targetLanguage: targetLanguage)
    }

    func receive(chunk: AudioChunk) -> TranscriptionStatus {
        service.receive(chunk: chunk)
    }

    func stop() -> TranscriptionStatus {
        service.stop()
    }

    private func attachHandlers() {
        service.setTranscriptHandler(transcriptHandler)
        service.setStatusHandler(statusHandler)
        attachModelStatusHandler()
    }

    private func attachModelStatusHandler() {
        if let modelManager = service as? LocalModelManaging {
            modelManager.setModelStatusHandler(modelStatusHandler)
        } else {
            modelStatusHandler?(.unavailable)
        }
    }

    private func detachHandlers() {
        service.setTranscriptHandler(nil)
        service.setStatusHandler(nil)
        (service as? LocalModelManaging)?.setModelStatusHandler(nil)
    }

    private static func makeService(for provider: TranscriptionProviderKind) -> TranscriptionServing {
        switch provider {
        case .debug:
            DebugTranscriptionService()
        case .whisperKit:
            LocalWhisperTranscriptionService(modelName: "tiny")
        }
    }
}
