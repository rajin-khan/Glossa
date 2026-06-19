import Foundation

@MainActor
final class GlossaStore: ObservableObject {
    @Published var targetLanguage: TranslationLanguage = TranslationLanguage.supported[0] {
        didSet {
            defaults.set(targetLanguage.code, forKey: DefaultsKey.targetLanguageCode)
        }
    }

    @Published var captureMode: CaptureMode = .systemAudio {
        didSet {
            defaults.set(captureMode.rawValue, forKey: DefaultsKey.captureMode)
        }
    }

    @Published var listeningState: ListeningState = .idle
    @Published var recentSegments: [TranscriptSegment] = []
    @Published var overlayVisible = true
    @Published var captureMetrics: AudioCaptureMetrics = .idle
    @Published var permissions: CapturePermissionSnapshot = .unknown
    @Published var pipelineStats: SubtitlePipelineStats = .idle
    @Published var transcriptionStatus: TranscriptionStatus = .idle

    private let captureService: AudioCaptureServing
    private let permissionService: CapturePermissionService
    private let transcriptionService: TranscriptionServing
    private let subtitlePipeline = SubtitlePipeline()
    private let defaults: UserDefaults
    private var previewTask: Task<Void, Never>?

    init(
        captureService: AudioCaptureServing = SystemAudioCaptureService(),
        permissionService: CapturePermissionService = CapturePermissionService(),
        transcriptionService: TranscriptionServing = DebugTranscriptionService(),
        defaults: UserDefaults = .standard
    ) {
        self.captureService = captureService
        self.permissionService = permissionService
        self.transcriptionService = transcriptionService
        self.defaults = defaults
        targetLanguage = Self.restoreTargetLanguage(from: defaults)
        captureMode = Self.restoreCaptureMode(from: defaults)
        captureService.setMetricsHandler { [weak self] metrics in
            guard let self else { return }
            var next = metrics
            next.bufferCount = self.captureMetrics.bufferCount + 1
            self.captureMetrics = next
        }
        captureService.setFrameHandler { [weak self] frame in
            guard let self else { return }
            self.pipelineStats = self.subtitlePipeline.receive(frame: frame)
        }
        subtitlePipeline.setChunkHandler { [weak self] chunk in
            guard let self else { return }
            self.transcriptionStatus = self.transcriptionService.receive(chunk: chunk)
        }
        recentSegments = [
            TranscriptSegment(
                sourceText: "Glossa is ready to listen.",
                translatedText: "Choose a target language, then start subtitles.",
                sourceLanguage: "Auto",
                isFinal: true
            )
        ]
    }

    var isListening: Bool {
        listeningState == .listening || listeningState == .previewing || listeningState == .starting
    }

    var currentSubtitle: TranscriptSegment? {
        recentSegments.last
    }

    func toggleListening() {
        isListening ? stopListening() : startListening()
    }

    func startListening() {
        previewTask?.cancel()

        switch captureMode {
        case .preview:
            startPreview()
        case .systemAudio, .microphone:
            startCapture()
        }
    }

    func stopListening() {
        previewTask?.cancel()
        previewTask = nil
        Task {
            await captureService.stop()
        }
        subtitlePipeline.reset()
        transcriptionStatus = transcriptionService.stop()
        pipelineStats = .idle
        captureMetrics = .idle
        listeningState = .idle
        append(
            source: "Listening paused.",
            translation: "Glossa is standing by.",
            sourceLanguage: "System",
            isFinal: true
        )
    }

    func clearTranscript() {
        recentSegments.removeAll()
    }

    func refreshPermissions() async {
        permissions = await permissionService.snapshot()
    }

    func requestScreenRecordingPermission() async {
        permissions = await permissionService.requestScreenRecording()
    }

    func requestMicrophonePermission() async {
        permissions = await permissionService.requestMicrophone()
    }

    private func startCapture() {
        listeningState = .starting
        transcriptionStatus = transcriptionService.start(targetLanguage: targetLanguage)

        Task {
            do {
                await refreshPermissions()
                if captureMode == .systemAudio && !permissions.screenRecording.isReady {
                    throw AudioCaptureError.screenRecordingPermissionRequired
                }
                if captureMode == .microphone && !permissions.microphone.isReady {
                    throw AudioCaptureError.microphonePermissionRequired
                }

                try await captureService.start(mode: captureMode)
                listeningState = .listening
                append(
                    source: "\(captureMode.rawValue) capture started.",
                    translation: "Audio is flowing. Realtime transcription comes next.",
                    sourceLanguage: "System",
                    isFinal: true
                )
            } catch {
                transcriptionStatus = transcriptionService.stop()
                listeningState = .failed(error.localizedDescription)
                append(
                    source: "Capture could not start.",
                    translation: error.localizedDescription,
                    sourceLanguage: "System",
                    isFinal: true
                )
            }
        }
    }

    private func startPreview() {
        listeningState = .previewing
        transcriptionStatus = transcriptionService.start(targetLanguage: targetLanguage)
        let samples = [
            TranscriptSegment(
                sourceText: "Bonjour, bienvenue dans Glossa.",
                translatedText: "Hello, welcome to Glossa.",
                sourceLanguage: "French",
                isFinal: true
            ),
            TranscriptSegment(
                sourceText: "La traduction apparaît pendant que l'audio continue.",
                translatedText: "The translation appears while the audio keeps playing.",
                sourceLanguage: "French",
                isFinal: false
            ),
            TranscriptSegment(
                sourceText: "On garde l'app légère, discrète, et toujours à portée.",
                translatedText: "We keep the app light, quiet, and always within reach.",
                sourceLanguage: "French",
                isFinal: true
            )
        ]

        previewTask = Task { [weak self] in
            var index = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                self?.append(segment: samples[index % samples.count])
                self?.captureMetrics = AudioCaptureMetrics(
                    level: [0.16, 0.36, 0.68, 0.44][index % 4],
                    peak: [0.32, 0.58, 0.88, 0.64][index % 4],
                    sampleCount: 48_000,
                    bufferCount: (self?.captureMetrics.bufferCount ?? 0) + 1,
                    sampleRate: 24_000,
                    channelCount: 1,
                    lastUpdated: .now
                )
                self?.pipelineStats = SubtitlePipelineStats(
                    receivedFrameCount: (self?.pipelineStats.receivedFrameCount ?? 0) + 1,
                    emittedChunkCount: (self?.pipelineStats.emittedChunkCount ?? 0) + (index.isMultiple(of: 2) ? 1 : 0),
                    bufferedAudioDuration: Double((index % 8) + 1) * 0.5,
                    lastFrameDuration: 0.5,
                    lastFrameLevel: [0.16, 0.36, 0.68, 0.44][index % 4],
                    isSpeechActive: true,
                    lastUpdated: .now
                )
                index += 1
            }
        }
    }

    private func append(source: String, translation: String, sourceLanguage: String, isFinal: Bool) {
        append(
            segment: TranscriptSegment(
                sourceText: source,
                translatedText: translation,
                sourceLanguage: sourceLanguage,
                isFinal: isFinal
            )
        )
    }

    private func append(segment: TranscriptSegment) {
        recentSegments.append(segment)
        if recentSegments.count > 12 {
            recentSegments.removeFirst(recentSegments.count - 12)
        }
    }

    private static func restoreTargetLanguage(from defaults: UserDefaults) -> TranslationLanguage {
        guard let code = defaults.string(forKey: DefaultsKey.targetLanguageCode),
              let language = TranslationLanguage.supported.first(where: { $0.code == code })
        else {
            return TranslationLanguage.supported[0]
        }

        return language
    }

    private static func restoreCaptureMode(from defaults: UserDefaults) -> CaptureMode {
        guard let rawValue = defaults.string(forKey: DefaultsKey.captureMode),
              let mode = CaptureMode(rawValue: rawValue)
        else {
            return .systemAudio
        }

        return mode
    }
}

private enum DefaultsKey {
    static let targetLanguageCode = "targetLanguageCode"
    static let captureMode = "captureMode"
}
