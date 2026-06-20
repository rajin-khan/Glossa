import Foundation

#if canImport(ScreenCaptureKit)
import AudioToolbox
import CoreMedia

enum AudioBufferAnalyzer {
    struct Analysis {
        var metrics: AudioCaptureMetrics
        var frame: AudioFrame
    }

    static func analysis(from sampleBuffer: CMSampleBuffer) -> Analysis? {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee
        else {
            return nil
        }

        var blockBuffer: CMBlockBuffer?
        var audioBufferList = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: AudioBuffer(mNumberChannels: 0, mDataByteSize: 0, mData: nil)
        )

        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: kCFAllocatorDefault,
            blockBufferMemoryAllocator: kCFAllocatorDefault,
            flags: UInt32(kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment),
            blockBufferOut: &blockBuffer
        )

        guard status == noErr,
              let data = audioBufferList.mBuffers.mData,
              audioBufferList.mBuffers.mDataByteSize > 0
        else {
            return nil
        }

        let sampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
        let byteCount = Int(audioBufferList.mBuffers.mDataByteSize)
        let samples = normalizedSamples(
            data: data,
            byteCount: byteCount,
            streamDescription: streamDescription
        )
        let level = levels(from: samples)

        let metrics = AudioCaptureMetrics(
            level: level.rms,
            peak: level.peak,
            sampleCount: sampleCount,
            bufferCount: 1,
            sampleRate: streamDescription.mSampleRate,
            channelCount: Int(streamDescription.mChannelsPerFrame),
            lastUpdated: .now
        )

        let frame = AudioFrame(
            samples: samples,
            sampleRate: streamDescription.mSampleRate,
            channelCount: Int(streamDescription.mChannelsPerFrame),
            capturedAt: .now
        )

        return Analysis(metrics: metrics, frame: frame)
    }

    private static func normalizedSamples(
        data: UnsafeMutableRawPointer,
        byteCount: Int,
        streamDescription: AudioStreamBasicDescription
    ) -> [Float] {
        let flags = streamDescription.mFormatFlags
        let isFloat = flags & kAudioFormatFlagIsFloat != 0
        let isSignedInteger = flags & kAudioFormatFlagIsSignedInteger != 0

        if isFloat && streamDescription.mBitsPerChannel == 32 {
            let values = data.assumingMemoryBound(to: Float.self)
            let count = max(1, byteCount / MemoryLayout<Float>.size)
            return (0..<count).map { min(1, max(-1, values[$0])) }
        }

        if isSignedInteger && streamDescription.mBitsPerChannel == 16 {
            let values = data.assumingMemoryBound(to: Int16.self)
            let count = max(1, byteCount / MemoryLayout<Int16>.size)
            return (0..<count).map { Float(values[$0]) / Float(Int16.max) }
        }

        return []
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

