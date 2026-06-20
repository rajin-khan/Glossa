import Foundation

struct PreviewSessionUpdate {
    let segment: TranscriptSegment
    let captureMetrics: AudioCaptureMetrics
    let pipelineStats: SubtitlePipelineStats
}

@MainActor
final class PreviewSession {
    private var task: Task<Void, Never>?

    func start(updateHandler: @escaping @MainActor (PreviewSessionUpdate) -> Void) {
        stop()

        task = Task {
            var index = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                updateHandler(Self.makeUpdate(index: index))
                index += 1
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private static func makeUpdate(index: Int) -> PreviewSessionUpdate {
        let segments = [
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
        let levels = [0.16, 0.36, 0.68, 0.44]
        let peaks = [0.32, 0.58, 0.88, 0.64]
        let frameCount = index + 1

        return PreviewSessionUpdate(
            segment: segments[index % segments.count],
            captureMetrics: AudioCaptureMetrics(
                level: levels[index % levels.count],
                peak: peaks[index % peaks.count],
                sampleCount: 48_000,
                bufferCount: frameCount,
                sampleRate: 24_000,
                channelCount: 1,
                lastUpdated: .now
            ),
            pipelineStats: SubtitlePipelineStats(
                receivedFrameCount: frameCount,
                emittedChunkCount: (frameCount + 1) / 2,
                bufferedAudioDuration: Double((index % 8) + 1) * 0.5,
                lastFrameDuration: 0.5,
                lastFrameLevel: levels[index % levels.count],
                isSpeechActive: true,
                lastUpdated: .now
            )
        )
    }
}
