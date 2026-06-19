import Foundation

@MainActor
final class GlossaStore: ObservableObject {
    @Published var targetLanguage: TranslationLanguage = TranslationLanguage.supported[0]
    @Published var captureMode: CaptureMode = .systemAudio
    @Published var listeningState: ListeningState = .idle
    @Published var recentSegments: [TranscriptSegment] = []
    @Published var overlayVisible = true

    private let captureService: AudioCaptureServing
    private var previewTask: Task<Void, Never>?

    init(captureService: AudioCaptureServing = SystemAudioCaptureService()) {
        self.captureService = captureService
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

    private func startCapture() {
        listeningState = .starting

        Task {
            do {
                try await captureService.start(mode: captureMode)
                listeningState = .listening
                append(
                    source: "\(captureMode.rawValue) capture started.",
                    translation: "Audio is flowing. Realtime transcription comes next.",
                    sourceLanguage: "System",
                    isFinal: true
                )
            } catch {
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
}
