import Foundation
import WhisperKit

@MainActor
final class LocalWhisperTranscriptionService: TranscriptionServing {
    private let providerName = "WhisperKit"
    private let modelName: String

    private var whisperKit: WhisperKit?
    private var initializationTask: Task<Void, Never>?
    private var transcriptionTask: Task<Void, Never>?
    private var pendingChunks: [AudioChunk] = []
    private var transcriptHandler: (@MainActor @Sendable (TranscriptionEvent) -> Void)?
    private var statusHandler: (@MainActor @Sendable (TranscriptionStatus) -> Void)?
    private var isRunning = false
    private var chunkCount = 0
    private var runID = UUID()

    init(modelName: String = "tiny") {
        self.modelName = modelName
    }

    func setTranscriptHandler(_ handler: (@MainActor @Sendable (TranscriptionEvent) -> Void)?) {
        transcriptHandler = handler
    }

    func setStatusHandler(_ handler: (@MainActor @Sendable (TranscriptionStatus) -> Void)?) {
        statusHandler = handler
    }

    func start(targetLanguage: TranslationLanguage) -> TranscriptionStatus {
        _ = stop()
        isRunning = true
        runID = UUID()
        let currentRunID = runID

        if whisperKit != nil {
            let status = TranscriptionStatus.ready(provider: providerName)
            statusHandler?(status)
            return status
        }

        let status = TranscriptionStatus.loading(provider: providerName, detail: "loading \(modelName) model")
        statusHandler?(status)
        initializationTask = Task { [weak self] in
            guard let self else { return }

            do {
                let config = WhisperKitConfig(
                    model: modelName,
                    verbose: false,
                    logLevel: .error,
                    prewarm: true,
                    load: true,
                    download: true
                )
                let engine = try await WhisperKit(config)
                guard self.isRunning, self.runID == currentRunID else { return }
                self.whisperKit = engine
                self.statusHandler?(.ready(provider: self.providerName))
                self.processNextChunk()
            } catch {
                guard self.runID == currentRunID else { return }
                self.isRunning = false
                self.pendingChunks.removeAll()
                self.statusHandler?(.failed(error.localizedDescription))
            }
        }

        return status
    }

    func receive(chunk: AudioChunk) -> TranscriptionStatus {
        guard isRunning else { return .idle }

        chunkCount += 1
        pendingChunks.append(chunk)
        processNextChunk()

        let status = TranscriptionStatus.receiving(provider: providerName, chunkCount: chunkCount)
        statusHandler?(status)
        return status
    }

    @discardableResult
    func stop() -> TranscriptionStatus {
        isRunning = false
        runID = UUID()
        chunkCount = 0
        pendingChunks.removeAll()
        initializationTask?.cancel()
        initializationTask = nil
        transcriptionTask?.cancel()
        transcriptionTask = nil
        statusHandler?(.stopped)
        return .stopped
    }

    private func processNextChunk() {
        guard transcriptionTask == nil,
              let whisperKit,
              !pendingChunks.isEmpty,
              isRunning
        else {
            return
        }

        let chunk = pendingChunks.removeFirst()
        let currentRunID = runID
        let audio = LocalAudioResampler.monoSamples(from: chunk, targetSampleRate: 16_000)
        let options = DecodingOptions(
            verbose: false,
            task: .transcribe,
            language: nil,
            usePrefillPrompt: false,
            detectLanguage: true,
            skipSpecialTokens: true,
            withoutTimestamps: true
        )

        transcriptionTask = Task { [weak self] in
            guard let self else { return }
            let results = await whisperKit.transcribe(audioArrays: [audio], decodeOptions: options)

            guard self.isRunning, self.runID == currentRunID else {
                self.transcriptionTask = nil
                return
            }

            if let result = results.first.flatMap({ $0 })?.first {
                let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    self.transcriptHandler?(
                        TranscriptionEvent(
                            text: text,
                            sourceLanguage: result.language,
                            isFinal: true
                        )
                    )
                }
            }

            self.transcriptionTask = nil
            self.processNextChunk()
        }
    }
}
