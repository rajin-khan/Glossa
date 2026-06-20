import AppKit
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
            guard oldValue != captureMode else { return }
            if isListening {
                stopListening()
            }
        }
    }

    @Published var transcriptionProvider: TranscriptionProviderKind = .whisperKit {
        didSet {
            defaults.set(transcriptionProvider.rawValue, forKey: DefaultsKey.transcriptionProvider)
            guard oldValue != transcriptionProvider else { return }

            if isListening {
                stopListening()
            }
            transcriptionService = Self.makeTranscriptionService(for: transcriptionProvider)
            attachTranscriptionHandlers()
        }
    }

    @Published var listeningState: ListeningState = .idle
    @Published var recentSegments: [TranscriptSegment] = []
    @Published var overlayVisible = false
    @Published var captureMetrics: AudioCaptureMetrics = .idle
    @Published var permissions: CapturePermissionSnapshot = .unknown
    @Published var pipelineStats: SubtitlePipelineStats = .idle
    @Published var transcriptionStatus: TranscriptionStatus = .idle
    @Published var localModelStatus: LocalModelStatus = .notPrepared
    @Published private(set) var availableTargetLanguages = TranslationLanguage.supported
    @Published var showsSourceText = true {
        didSet {
            defaults.set(showsSourceText, forKey: DefaultsKey.showsSourceText)
        }
    }
    @Published var overlayTextSize: OverlayTextSize = .standard {
        didSet {
            defaults.set(overlayTextSize.rawValue, forKey: DefaultsKey.overlayTextSize)
        }
    }

    let translationBroker = TranslationRequestBroker()

    private let captureService: AudioCaptureServing
    private let permissionService: CapturePermissionService
    private var transcriptionService: TranscriptionServing
    private let subtitlePipeline = SubtitlePipeline()
    private let defaults: UserDefaults
    private var previewTask: Task<Void, Never>?
    private var hasLoggedAudioFlow = false
    private var overlayVisibilityHandler: ((Bool) -> Void)?

    init(
        captureService: AudioCaptureServing = SystemAudioCaptureService(),
        permissionService: CapturePermissionService = CapturePermissionService(),
        transcriptionService: TranscriptionServing? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.captureService = captureService
        self.permissionService = permissionService
        self.defaults = defaults
        let restoredTargetLanguage = Self.restoreTargetLanguage(from: defaults)
        let restoredCaptureMode = Self.restoreCaptureMode(from: defaults)
        let restoredProvider = Self.restoreTranscriptionProvider(from: defaults)
        let restoredOverlayTextSize = Self.restoreOverlayTextSize(from: defaults)
        targetLanguage = restoredTargetLanguage
        captureMode = restoredCaptureMode
        self.transcriptionProvider = restoredProvider
        showsSourceText = defaults.object(forKey: DefaultsKey.showsSourceText) as? Bool ?? true
        overlayTextSize = restoredOverlayTextSize
        self.transcriptionService = transcriptionService ?? Self.makeTranscriptionService(for: restoredProvider)
        captureService.setMetricsHandler { [weak self] metrics in
            guard let self else { return }
            if metrics.lastUpdated != nil, !self.hasLoggedAudioFlow {
                self.hasLoggedAudioFlow = true
                GlossaLog.capture.info(
                    "Received first audio buffer at \(metrics.sampleRate, privacy: .public) Hz"
                )
            }
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
        attachTranscriptionHandlers()
        translationBroker.setResultHandler { [weak self] segment in
            self?.append(segment: segment)
        }
        recentSegments = []
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
        overlayVisible = true
        overlayVisibilityHandler?(true)
        GlossaLog.app.info(
            "Starting listening with capture=\(self.captureMode.rawValue, privacy: .public) provider=\(self.transcriptionProvider.rawValue, privacy: .public)"
        )

        switch captureMode {
        case .preview:
            startPreview()
        case .systemAudio, .microphone:
            startCapture()
        }
    }

    func stopListening() {
        GlossaLog.app.info("Stopping listening")
        previewTask?.cancel()
        previewTask = nil
        Task {
            await captureService.stop()
        }
        subtitlePipeline.reset()
        transcriptionStatus = transcriptionService.stop()
        translationBroker.reset()
        pipelineStats = .idle
        captureMetrics = .idle
        hasLoggedAudioFlow = false
        listeningState = .idle
        overlayVisible = false
        overlayVisibilityHandler?(false)
    }

    func clearTranscript() {
        recentSegments.removeAll()
    }

    func setOverlayVisibilityHandler(_ handler: @escaping (Bool) -> Void) {
        overlayVisibilityHandler = handler
    }

    func toggleOverlay() {
        overlayVisible.toggle()
        overlayVisibilityHandler?(overlayVisible)
    }

    func refreshPermissions() async {
        permissions = await permissionService.snapshot()
    }

    func refreshAvailableTargetLanguages() async {
        let languages = await TranslationLanguageCatalog.supportedLanguages()
        if languages.contains(where: { $0.code == targetLanguage.code }) {
            availableTargetLanguages = languages
        } else {
            availableTargetLanguages = (languages + [targetLanguage]).sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        }
    }

    func requestScreenRecordingPermission() async {
        permissions = await permissionService.requestScreenRecording()
    }

    func requestMicrophonePermission() async {
        permissions = await permissionService.requestMicrophone()
    }

    func prepareLocalModel() {
        guard let modelManager = transcriptionService as? LocalModelManaging else {
            localModelStatus = .unavailable
            return
        }
        modelManager.prepareModel()
    }

    func prepareCachedLocalModel() {
        guard case .downloaded = localModelStatus else { return }
        prepareLocalModel()
    }

    func restartApplication() {
        let bundleURL = Bundle.main.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        GlossaLog.app.info("Restarting Glossa for refreshed privacy permissions")

        NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { _, error in
            if let error {
                GlossaLog.app.error("Restart failed: \(error.localizedDescription, privacy: .public)")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.terminate(nil)
        }
    }

    func handleLaunchArguments(_ arguments: [String]) {
        guard !isListening else { return }

        if arguments.contains("--smoke-microphone") {
            GlossaLog.app.info("Applying microphone smoke-test launch argument")
            applyTransientCaptureMode(.microphone)
            startListening()
        } else if arguments.contains("--smoke-system-audio") {
            GlossaLog.app.info("Applying system-audio smoke-test launch argument")
            applyTransientCaptureMode(.systemAudio)
            startListening()
        } else if arguments.contains("--preview-subtitles") {
            GlossaLog.app.info("Applying subtitle preview launch argument")
            applyTransientCaptureMode(.preview)
            startListening()
        }
    }

    private func applyTransientCaptureMode(_ mode: CaptureMode) {
        let persistedMode = defaults.string(forKey: DefaultsKey.captureMode)
        captureMode = mode
        if let persistedMode {
            defaults.set(persistedMode, forKey: DefaultsKey.captureMode)
        } else {
            defaults.removeObject(forKey: DefaultsKey.captureMode)
        }
    }

    private func startCapture() {
        listeningState = .starting
        transcriptionStatus = transcriptionService.start(targetLanguage: targetLanguage)

        Task {
            do {
                await refreshPermissions()
                if captureMode == .systemAudio && !permissions.screenRecording.isReady {
                    GlossaLog.capture.info("Requesting Screen Recording permission")
                    await requestScreenRecordingPermission()
                    if !permissions.screenRecording.isReady {
                        throw AudioCaptureError.screenRecordingPermissionRequired
                    }
                }
                if captureMode == .microphone && !permissions.microphone.isReady {
                    GlossaLog.capture.info("Requesting microphone permission")
                    await requestMicrophonePermission()
                    if !permissions.microphone.isReady {
                        throw AudioCaptureError.microphonePermissionRequired
                    }
                }

                try await captureService.start(mode: captureMode)
                listeningState = .listening
                GlossaLog.capture.info("Capture started successfully")
            } catch {
                GlossaLog.capture.error("Capture failed: \(error.localizedDescription, privacy: .public)")
                transcriptionStatus = transcriptionService.stop()
                listeningState = .failed(error.localizedDescription)
                overlayVisible = false
                overlayVisibilityHandler?(false)
            }
        }
    }

    private func startPreview() {
        listeningState = .previewing
        transcriptionStatus = .ready(provider: "Preview")
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

    private func append(segment: TranscriptSegment) {
        recentSegments.append(segment)
        if recentSegments.count > 12 {
            recentSegments.removeFirst(recentSegments.count - 12)
        }
    }

    private func attachTranscriptionHandlers() {
        if let modelManager = transcriptionService as? LocalModelManaging {
            modelManager.setModelStatusHandler { [weak self] status in
                self?.localModelStatus = status
            }
        } else {
            localModelStatus = .unavailable
        }
        transcriptionService.setStatusHandler { [weak self] status in
            self?.transcriptionStatus = status
        }
        transcriptionService.setTranscriptHandler { [weak self] event in
            guard let self else { return }
            self.translationBroker.submit(event: event, targetLanguage: self.targetLanguage)
        }
    }

    private static func restoreTargetLanguage(from defaults: UserDefaults) -> TranslationLanguage {
        guard let code = defaults.string(forKey: DefaultsKey.targetLanguageCode) else {
            return TranslationLanguage.supported[0]
        }

        return TranslationLanguage.supported.first(where: { $0.code == code })
            ?? TranslationLanguageCatalog.makeLanguage(identifier: code)
    }

    private static func restoreCaptureMode(from defaults: UserDefaults) -> CaptureMode {
        guard let rawValue = defaults.string(forKey: DefaultsKey.captureMode),
              let mode = CaptureMode(rawValue: rawValue)
        else {
            return .systemAudio
        }

        return mode
    }

    private static func restoreTranscriptionProvider(from defaults: UserDefaults) -> TranscriptionProviderKind {
        guard let rawValue = defaults.string(forKey: DefaultsKey.transcriptionProvider),
              let provider = TranscriptionProviderKind(rawValue: rawValue)
        else {
            return .whisperKit
        }

        return provider
    }

    private static func restoreOverlayTextSize(from defaults: UserDefaults) -> OverlayTextSize {
        guard let rawValue = defaults.string(forKey: DefaultsKey.overlayTextSize),
              let size = OverlayTextSize(rawValue: rawValue)
        else {
            return .standard
        }

        return size
    }

    private static func makeTranscriptionService(for provider: TranscriptionProviderKind) -> TranscriptionServing {
        switch provider {
        case .debug:
            DebugTranscriptionService()
        case .whisperKit:
            LocalWhisperTranscriptionService(modelName: "tiny")
        }
    }
}

private enum DefaultsKey {
    static let targetLanguageCode = "targetLanguageCode"
    static let captureMode = "captureMode"
    static let transcriptionProvider = "transcriptionProvider"
    static let showsSourceText = "showsSourceText"
    static let overlayTextSize = "overlayTextSize"
}
