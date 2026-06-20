import Foundation

@MainActor
final class GlossaStore: ObservableObject {
    @Published var targetLanguage: TranslationLanguage = TranslationLanguage.supported[0] {
        didSet {
            preferences.saveTargetLanguage(targetLanguage)
        }
    }

    @Published var captureMode: CaptureMode = .systemAudio {
        didSet {
            preferences.saveCaptureMode(captureMode)
            guard oldValue != captureMode else { return }
            if isListening {
                stopListening()
            }
        }
    }

    @Published var transcriptionProvider: TranscriptionProviderKind = .whisperKit {
        didSet {
            preferences.saveTranscriptionProvider(transcriptionProvider)
            guard oldValue != transcriptionProvider else { return }

            if isListening {
                stopListening()
            }
            transcriptionCoordinator.replaceService(for: transcriptionProvider)
        }
    }

    @Published var listeningState: ListeningState = .idle
    @Published var recentSegments: [TranscriptSegment] = []
    @Published private var activeSubtitle: TranscriptSegment?
    @Published var overlayVisible = false
    @Published var captureMetrics: AudioCaptureMetrics = .idle
    @Published var permissions: CapturePermissionSnapshot = .unknown
    @Published var pipelineStats: SubtitlePipelineStats = .idle
    @Published var transcriptionStatus: TranscriptionStatus = .idle
    @Published var localModelStatus: LocalModelStatus = .notPrepared
    @Published private(set) var availableTargetLanguages = TranslationLanguage.supported
    @Published var showsSourceText = true {
        didSet {
            preferences.saveShowsSourceText(showsSourceText)
            notifyOverlayAppearanceChanged()
        }
    }
    @Published var overlayScale: Double = 1 {
        didSet {
            let clampedScale = OverlayLayoutMetrics.clampedScale(overlayScale)
            if overlayScale != clampedScale {
                overlayScale = clampedScale
                return
            }
            preferences.saveOverlayScale(overlayScale)
            notifyOverlayAppearanceChanged()
        }
    }
    @Published var fallbackTranslationURLString = "" {
        didSet {
            preferences.saveFallbackTranslationURL(fallbackTranslationURLString)
            translationBroker.configureFallback(endpoint: Self.fallbackTranslationURL(from: fallbackTranslationURLString))
        }
    }

    let translationBroker = TranslationRequestBroker()

    private let captureCoordinator: CaptureSessionCoordinator
    private let transcriptionCoordinator: TranscriptionCoordinator
    private let systemApplicationService: SystemApplicationServing
    private let subtitlePipeline = SubtitlePipeline()
    private let subtitleTimeline = SubtitleTimeline()
    private let previewSession = PreviewSession()
    private let preferences: GlossaPreferences
    private var hasLoggedAudioFlow = false
    private var overlayVisibilityHandler: ((Bool) -> Void)?
    private var overlayAppearanceChangeHandler: (() -> Void)?
    private var overlayPositionResetHandler: (() -> Void)?

    init(
        captureService: AudioCaptureServing = SystemAudioCaptureService(),
        permissionService: CapturePermissionServing = CapturePermissionService(),
        systemApplicationService: SystemApplicationServing = SystemApplicationService(),
        transcriptionService: TranscriptionServing? = nil,
        defaults: UserDefaults = .standard
    ) {
        let captureCoordinator = CaptureSessionCoordinator(
            captureService: captureService,
            permissionService: permissionService
        )
        self.captureCoordinator = captureCoordinator
        self.systemApplicationService = systemApplicationService
        let preferences = GlossaPreferences(defaults: defaults)
        self.preferences = preferences
        let snapshot = preferences.load()
        targetLanguage = snapshot.targetLanguage
        captureMode = snapshot.captureMode
        self.transcriptionProvider = snapshot.transcriptionProvider
        showsSourceText = snapshot.showsSourceText
        overlayScale = snapshot.overlayScale
        fallbackTranslationURLString = snapshot.fallbackTranslationURLString
        self.transcriptionCoordinator = TranscriptionCoordinator(
            provider: snapshot.transcriptionProvider,
            service: transcriptionService
        )
        captureCoordinator.setMetricsHandler { [weak self] metrics in
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
        captureCoordinator.setFrameHandler { [weak self] frame in
            guard let self else { return }
            self.pipelineStats = self.subtitlePipeline.receive(frame: frame)
        }
        subtitlePipeline.setChunkHandler { [weak self] chunk in
            guard let self else { return }
            self.transcriptionStatus = self.transcriptionCoordinator.receive(chunk: chunk)
        }
        subtitleTimeline.setChangeHandler { [weak self] snapshot in
            guard let self else { return }
            activeSubtitle = snapshot.activeSubtitle
            recentSegments = snapshot.recentSegments
            notifyOverlayAppearanceChanged()
        }
        transcriptionCoordinator.setModelStatusHandler { [weak self] status in
            self?.localModelStatus = status
        }
        transcriptionCoordinator.setStatusHandler { [weak self] status in
            self?.transcriptionStatus = status
        }
        transcriptionCoordinator.setTranscriptHandler { [weak self] event in
            guard let self else { return }
            self.translationBroker.submit(event: event, targetLanguage: self.targetLanguage)
        }
        translationBroker.setResultHandler { [weak self] segment in
            self?.subtitleTimeline.append(segment)
        }
        translationBroker.configureFallback(endpoint: Self.fallbackTranslationURL(from: fallbackTranslationURLString))
        recentSegments = []
    }

    var isListening: Bool {
        listeningState == .listening || listeningState == .previewing || listeningState == .starting
    }

    var currentSubtitle: TranscriptSegment? {
        activeSubtitle
    }

    var overlayMetrics: OverlayLayoutMetrics {
        OverlayLayoutMetrics(scale: overlayScale)
    }

    func toggleListening() {
        isListening ? stopListening() : startListening()
    }

    func startListening() {
        previewSession.stop()
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
        previewSession.stop()
        captureCoordinator.stop()
        subtitlePipeline.reset()
        transcriptionStatus = transcriptionCoordinator.stop()
        translationBroker.reset()
        pipelineStats = .idle
        captureMetrics = .idle
        hasLoggedAudioFlow = false
        listeningState = .idle
        subtitleTimeline.clearActiveSubtitle()
    }

    func clearTranscript() {
        subtitleTimeline.clearAll()
    }

    func setOverlayVisibilityHandler(_ handler: @escaping (Bool) -> Void) {
        overlayVisibilityHandler = handler
    }

    func setOverlayAppearanceChangeHandler(_ handler: @escaping () -> Void) {
        overlayAppearanceChangeHandler = handler
    }

    func setOverlayPositionResetHandler(_ handler: @escaping () -> Void) {
        overlayPositionResetHandler = handler
    }

    func toggleOverlay() {
        overlayVisible.toggle()
        overlayVisibilityHandler?(overlayVisible)
    }

    func resetOverlayPosition() {
        overlayPositionResetHandler?()
        if !overlayVisible {
            overlayVisible = true
            overlayVisibilityHandler?(true)
        }
    }

    func resetOverlayAppearance() {
        showsSourceText = true
        overlayScale = 1
    }

    func refreshPermissions() async {
        permissions = await captureCoordinator.permissions()
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
        permissions = await captureCoordinator.requestScreenRecordingPermission()
        if !permissions.screenRecording.isReady {
            systemApplicationService.openSystemAudioPermissionSettings()
        }
    }

    func requestMicrophonePermission() async {
        permissions = await captureCoordinator.requestMicrophonePermission()
        if !permissions.microphone.isReady {
            systemApplicationService.openMicrophonePermissionSettings()
        }
    }

    func openSystemAudioPermissionSettings() {
        systemApplicationService.openSystemAudioPermissionSettings()
    }

    func openMicrophonePermissionSettings() {
        systemApplicationService.openMicrophonePermissionSettings()
    }

    func prepareLocalModel() {
        transcriptionCoordinator.prepareModel()
    }

    func prepareCachedLocalModel() {
        guard case .downloaded = localModelStatus else { return }
        prepareLocalModel()
    }

    func restartApplication() {
        systemApplicationService.restartApplication()
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
        preferences.withTransientCaptureMode(mode) {
            captureMode = mode
        }
    }

    private func startCapture() {
        listeningState = .starting
        transcriptionStatus = transcriptionCoordinator.start(targetLanguage: targetLanguage)
        captureCoordinator.start(
            mode: captureMode,
            permissionsUpdated: { [weak self] permissions in
                self?.permissions = permissions
            },
            didStart: { [weak self] in
                self?.listeningState = .listening
                GlossaLog.capture.info("Capture started successfully")
            },
            didFail: { [weak self] error in
                guard let self else { return }
                GlossaLog.capture.error("Capture failed: \(error.localizedDescription, privacy: .public)")
                transcriptionStatus = transcriptionCoordinator.stop()
                listeningState = .failed(error.localizedDescription)
                subtitleTimeline.clearActiveSubtitle()
            }
        )
    }

    private func startPreview() {
        listeningState = .previewing
        transcriptionStatus = .ready(provider: "Preview")
        previewSession.start { [weak self] update in
            guard let self else { return }
            subtitleTimeline.append(update.segment)
            captureMetrics = update.captureMetrics
            pipelineStats = update.pipelineStats
        }
    }

    private func notifyOverlayAppearanceChanged() {
        overlayAppearanceChangeHandler?()
    }

    private static func fallbackTranslationURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }
}
