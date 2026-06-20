import Foundation
import WhisperKit

@MainActor
final class LocalWhisperTranscriptionService: TranscriptionServing, LocalModelManaging {
    private let providerName = "WhisperKit"
    private let modelName: String
    private let maximumPendingChunks = 3

    private var whisperKit: WhisperKit?
    private var modelPreparationTask: Task<Void, Never>?
    private var transcriptionTask: Task<Void, Never>?
    private var pendingChunks: [AudioChunk] = []
    private var transcriptHandler: (@MainActor @Sendable (TranscriptionEvent) -> Void)?
    private var statusHandler: (@MainActor @Sendable (TranscriptionStatus) -> Void)?
    private var modelStatusHandler: (@MainActor @Sendable (LocalModelStatus) -> Void)?
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

    func setModelStatusHandler(_ handler: (@MainActor @Sendable (LocalModelStatus) -> Void)?) {
        modelStatusHandler = handler
        if whisperKit != nil {
            handler?(.ready(model: modelName))
        } else if LocalModelDirectory.cachedModelFolder(modelName: modelName) != nil {
            handler?(.downloaded(model: modelName))
        } else {
            handler?(.notPrepared)
        }
    }

    func prepareModel() {
        beginModelPreparation()
    }

    func start(targetLanguage: TranslationLanguage) -> TranscriptionStatus {
        _ = stop()
        isRunning = true
        runID = UUID()

        if whisperKit != nil {
            let status = TranscriptionStatus.ready(provider: providerName)
            statusHandler?(status)
            return status
        }

        let status = TranscriptionStatus.loading(provider: providerName, detail: "loading \(modelName) model")
        statusHandler?(status)
        beginModelPreparation()

        return status
    }

    private func beginModelPreparation() {
        guard whisperKit == nil, modelPreparationTask == nil else { return }

        GlossaLog.transcription.info("Preparing local Whisper model: \(self.modelName, privacy: .public)")
        modelStatusHandler?(.downloading(progress: 0))
        modelPreparationTask = Task { [weak self] in
            guard let self else { return }

            do {
                let modelFolder: URL
                if let cachedModelFolder = LocalModelDirectory.cachedModelFolder(modelName: modelName) {
                    modelFolder = cachedModelFolder
                } else {
                    let downloadBase = try LocalModelDirectory.url()
                    modelFolder = try await WhisperKit.download(
                        variant: modelName,
                        downloadBase: downloadBase
                    ) { progress in
                        let fraction = progress.fractionCompleted
                        Task { @MainActor [weak self] in
                            self?.modelStatusHandler?(.downloading(progress: fraction))
                        }
                    }
                }
                self.modelStatusHandler?(.loading)
                let config = WhisperKitConfig(
                    model: modelName,
                    modelFolder: modelFolder.path,
                    verbose: false,
                    logLevel: .error,
                    prewarm: false,
                    load: true,
                    download: false
                )
                let engine = try await WhisperKit(config)
                self.whisperKit = engine
                self.modelPreparationTask = nil
                self.modelStatusHandler?(.ready(model: self.modelName))
                GlossaLog.transcription.info("Local Whisper model ready")

                if self.isRunning {
                    self.statusHandler?(.ready(provider: self.providerName))
                    self.processNextChunk()
                }
            } catch {
                self.modelPreparationTask = nil
                self.pendingChunks.removeAll()
                self.modelStatusHandler?(.failed(error.localizedDescription))
                self.statusHandler?(.failed(error.localizedDescription))
                GlossaLog.transcription.error(
                    "Local model preparation failed: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
    }

    func receive(chunk: AudioChunk) -> TranscriptionStatus {
        guard isRunning else { return .idle }

        chunkCount += 1
        pendingChunks.append(chunk)
        if pendingChunks.count > maximumPendingChunks {
            pendingChunks.removeFirst(pendingChunks.count - maximumPendingChunks)
        }

        guard whisperKit != nil else {
            let status = TranscriptionStatus.loading(
                provider: providerName,
                detail: "loading model · \(pendingChunks.count) queued"
            )
            statusHandler?(status)
            return status
        }

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
                    GlossaLog.transcription.info(
                        "Completed local transcription language=\(result.language, privacy: .public) characters=\(text.count, privacy: .public)"
                    )
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
