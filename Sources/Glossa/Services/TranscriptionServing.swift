import Foundation

@MainActor
protocol TranscriptionServing: AnyObject {
    func setTranscriptHandler(_ handler: (@MainActor @Sendable (TranscriptionEvent) -> Void)?)
    func setStatusHandler(_ handler: (@MainActor @Sendable (TranscriptionStatus) -> Void)?)
    func start(targetLanguage: TranslationLanguage) -> TranscriptionStatus
    func receive(chunk: AudioChunk) -> TranscriptionStatus
    func stop() -> TranscriptionStatus
}

@MainActor
final class DebugTranscriptionService: TranscriptionServing {
    private let providerName = "Debug ASR"
    private var chunkCount = 0
    private var isRunning = false
    private var transcriptHandler: (@MainActor @Sendable (TranscriptionEvent) -> Void)?
    private var statusHandler: (@MainActor @Sendable (TranscriptionStatus) -> Void)?

    func setTranscriptHandler(_ handler: (@MainActor @Sendable (TranscriptionEvent) -> Void)?) {
        transcriptHandler = handler
    }

    func setStatusHandler(_ handler: (@MainActor @Sendable (TranscriptionStatus) -> Void)?) {
        statusHandler = handler
    }

    func start(targetLanguage: TranslationLanguage) -> TranscriptionStatus {
        chunkCount = 0
        isRunning = true
        let status = TranscriptionStatus.ready(provider: providerName)
        statusHandler?(status)
        return status
    }

    func receive(chunk: AudioChunk) -> TranscriptionStatus {
        guard isRunning else {
            return .idle
        }

        chunkCount += 1
        if chunkCount.isMultiple(of: 3) {
            transcriptHandler?(
                TranscriptionEvent(
                    text: "Debug transcript chunk \(chunkCount)",
                    sourceLanguage: "Debug",
                    isFinal: true
                )
            )
        }
        let status = TranscriptionStatus.receiving(provider: providerName, chunkCount: chunkCount)
        statusHandler?(status)
        return status
    }

    func stop() -> TranscriptionStatus {
        isRunning = false
        chunkCount = 0
        statusHandler?(.stopped)
        return .stopped
    }
}
