import Foundation

@MainActor
protocol TranscriptionServing: AnyObject {
    func start(targetLanguage: TranslationLanguage) -> TranscriptionStatus
    func receive(chunk: AudioChunk) -> TranscriptionStatus
    func stop() -> TranscriptionStatus
}

@MainActor
final class DebugTranscriptionService: TranscriptionServing {
    private let providerName = "Debug ASR"
    private var chunkCount = 0
    private var isRunning = false

    func start(targetLanguage: TranslationLanguage) -> TranscriptionStatus {
        chunkCount = 0
        isRunning = true
        return .ready(provider: providerName)
    }

    func receive(chunk: AudioChunk) -> TranscriptionStatus {
        guard isRunning else {
            return .idle
        }

        chunkCount += 1
        return .receiving(provider: providerName, chunkCount: chunkCount)
    }

    func stop() -> TranscriptionStatus {
        isRunning = false
        chunkCount = 0
        return .stopped
    }
}
