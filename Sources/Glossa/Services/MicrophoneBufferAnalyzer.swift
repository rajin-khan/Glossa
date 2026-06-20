import Foundation

#if canImport(ScreenCaptureKit)
import AVFoundation

struct MicrophoneSampleBatch: Sendable {
    var samples: [Float]
    var sampleRate: Double
    var channelCount: Int
    var capturedAt: Date
}

enum MicrophoneBufferAnalyzer {
    struct Analysis {
        var metrics: AudioCaptureMetrics
        var frame: AudioFrame
    }

    static func capture(from buffer: AVAudioPCMBuffer) -> MicrophoneSampleBatch? {
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return nil }

        let audioBuffers = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
        guard !audioBuffers.isEmpty else { return nil }

        var samples = [Float](repeating: 0, count: frameLength)

        if audioBuffers.count == 1 {
            guard let data = audioBuffers[0].mData?.assumingMemoryBound(to: Float.self) else {
                return nil
            }

            let channelsInBuffer = max(1, Int(audioBuffers[0].mNumberChannels))
            let sourceChannels = max(1, min(Int(buffer.format.channelCount), channelsInBuffer))
            let availableFrames = min(
                frameLength,
                Int(audioBuffers[0].mDataByteSize) / MemoryLayout<Float>.size / sourceChannels
            )

            for frameIndex in 0..<availableFrames {
                let baseIndex = frameIndex * sourceChannels
                var mixedSample: Float = 0
                for channelIndex in 0..<sourceChannels {
                    mixedSample += data[baseIndex + channelIndex]
                }
                samples[frameIndex] = clamped(mixedSample / Float(sourceChannels))
            }
        } else {
            let sourceChannels = max(1, min(Int(buffer.format.channelCount), audioBuffers.count))

            for channelIndex in 0..<sourceChannels {
                guard let data = audioBuffers[channelIndex].mData?.assumingMemoryBound(to: Float.self) else {
                    continue
                }

                let availableFrames = min(
                    frameLength,
                    Int(audioBuffers[channelIndex].mDataByteSize) / MemoryLayout<Float>.size
                )

                for frameIndex in 0..<availableFrames {
                    samples[frameIndex] += data[frameIndex]
                }
            }

            for frameIndex in samples.indices {
                samples[frameIndex] = clamped(samples[frameIndex] / Float(sourceChannels))
            }
        }

        return MicrophoneSampleBatch(
            samples: samples,
            sampleRate: buffer.format.sampleRate,
            channelCount: 1,
            capturedAt: .now
        )
    }

    static func analysis(from batch: MicrophoneSampleBatch) -> Analysis? {
        guard !batch.samples.isEmpty else { return nil }

        let samples = batch.samples
        let level = levels(from: samples)
        let metrics = AudioCaptureMetrics(
            level: level.rms,
            peak: level.peak,
            sampleCount: samples.count,
            bufferCount: 1,
            sampleRate: batch.sampleRate,
            channelCount: batch.channelCount,
            lastUpdated: .now
        )
        let frame = AudioFrame(
            samples: samples,
            sampleRate: batch.sampleRate,
            channelCount: batch.channelCount,
            capturedAt: batch.capturedAt
        )

        return Analysis(metrics: metrics, frame: frame)
    }

    private static func clamped(_ sample: Float) -> Float {
        min(1, max(-1, sample))
    }

    private static func levels(from samples: [Float]) -> (rms: Double, peak: Double) {
        guard !samples.isEmpty else { return (0, 0) }

        var sum = 0.0
        var peak = 0.0

        for sample in samples {
            let magnitude = min(1, abs(Double(sample)))
            sum += magnitude * magnitude
            peak = max(peak, magnitude)
        }

        return (sqrt(sum / Double(samples.count)), peak)
    }
}
#endif

