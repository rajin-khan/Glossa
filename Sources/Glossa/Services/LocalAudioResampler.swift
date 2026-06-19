import Foundation

enum LocalAudioResampler {
    static func monoSamples(from chunk: AudioChunk, targetSampleRate: Double) -> [Float] {
        let mono = downmixToMono(chunk)
        return resample(mono, sourceRate: chunk.sampleRate, targetRate: targetSampleRate)
    }

    private static func downmixToMono(_ chunk: AudioChunk) -> [Float] {
        guard chunk.channelCount > 1 else { return chunk.samples }

        let frameCount = chunk.samples.count / chunk.channelCount
        var output: [Float] = []
        output.reserveCapacity(frameCount)

        for frameIndex in 0..<frameCount {
            var mixed: Float = 0
            for channelIndex in 0..<chunk.channelCount {
                mixed += chunk.samples[frameIndex * chunk.channelCount + channelIndex]
            }
            output.append(mixed / Float(chunk.channelCount))
        }

        return output
    }

    private static func resample(_ samples: [Float], sourceRate: Double, targetRate: Double) -> [Float] {
        guard !samples.isEmpty, sourceRate > 0, targetRate > 0, sourceRate != targetRate else {
            return samples
        }

        let ratio = sourceRate / targetRate
        let outputCount = max(1, Int(Double(samples.count) / ratio))
        var output: [Float] = []
        output.reserveCapacity(outputCount)

        for outputIndex in 0..<outputCount {
            let sourcePosition = Double(outputIndex) * ratio
            let lowerIndex = min(Int(sourcePosition), samples.count - 1)
            let upperIndex = min(lowerIndex + 1, samples.count - 1)
            let fraction = Float(sourcePosition - Double(lowerIndex))
            output.append(samples[lowerIndex] + (samples[upperIndex] - samples[lowerIndex]) * fraction)
        }

        return output
    }
}
