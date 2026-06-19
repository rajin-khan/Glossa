import Foundation

@MainActor
final class SubtitlePipeline {
    private let targetChunkDuration: TimeInterval = 1.0
    private let silenceGate = 0.012

    private(set) var bufferedAudioDuration: TimeInterval = 0
    private(set) var receivedFrameCount = 0
    private(set) var emittedChunkCount = 0

    private var bufferedSamples: [Float] = []
    private var chunkStartedAt: Date?
    private var latestSampleRate = 24_000.0
    private var latestChannelCount = 1
    private var chunkLevelSum = 0.0
    private var chunkLevelFrameCount = 0
    private var chunkHandler: ((AudioChunk) -> Void)?

    func setChunkHandler(_ handler: ((AudioChunk) -> Void)?) {
        chunkHandler = handler
    }

    func receive(frame: AudioFrame) -> SubtitlePipelineStats {
        receivedFrameCount += 1
        latestSampleRate = frame.sampleRate
        latestChannelCount = frame.channelCount

        let level = rms(frame.samples)
        let isSpeechActive = level > silenceGate

        if isSpeechActive || !bufferedSamples.isEmpty {
            if bufferedSamples.isEmpty {
                chunkStartedAt = frame.capturedAt
            }

            bufferedSamples.append(contentsOf: frame.samples)
            chunkLevelSum += level
            chunkLevelFrameCount += 1
        }

        bufferedAudioDuration = duration(for: bufferedSamples)

        if bufferedAudioDuration >= targetChunkDuration {
            emitChunk(endedAt: frame.capturedAt)
        }

        return SubtitlePipelineStats(
            receivedFrameCount: receivedFrameCount,
            emittedChunkCount: emittedChunkCount,
            bufferedAudioDuration: bufferedAudioDuration,
            lastFrameDuration: frame.duration,
            lastFrameLevel: level,
            isSpeechActive: isSpeechActive,
            lastUpdated: .now
        )
    }

    func reset() {
        bufferedAudioDuration = 0
        receivedFrameCount = 0
        emittedChunkCount = 0
        bufferedSamples.removeAll(keepingCapacity: true)
        chunkStartedAt = nil
        chunkLevelSum = 0
        chunkLevelFrameCount = 0
    }

    private func emitChunk(endedAt: Date) {
        guard !bufferedSamples.isEmpty else { return }

        emittedChunkCount += 1
        let chunk = AudioChunk(
            samples: bufferedSamples,
            sampleRate: latestSampleRate,
            channelCount: latestChannelCount,
            averageLevel: chunkLevelFrameCount > 0 ? chunkLevelSum / Double(chunkLevelFrameCount) : 0,
            startedAt: chunkStartedAt ?? endedAt,
            endedAt: endedAt
        )

        bufferedSamples.removeAll(keepingCapacity: true)
        bufferedAudioDuration = 0
        chunkStartedAt = nil
        chunkLevelSum = 0
        chunkLevelFrameCount = 0

        chunkHandler?(chunk)
    }

    private func duration(for samples: [Float]) -> TimeInterval {
        guard latestSampleRate > 0, latestChannelCount > 0 else { return 0 }
        return Double(samples.count) / latestSampleRate / Double(latestChannelCount)
    }

    private func rms(_ samples: [Float]) -> Double {
        guard !samples.isEmpty else { return 0 }

        var sum = 0.0
        for sample in samples {
            let magnitude = min(1, abs(Double(sample)))
            sum += magnitude * magnitude
        }

        return sqrt(sum / Double(samples.count))
    }
}
