import Foundation

#if canImport(ScreenCaptureKit)
import AudioToolbox
import CoreMedia
import ScreenCaptureKit
#endif

@MainActor
final class SystemAudioCaptureService: NSObject, AudioCaptureServing {
    private nonisolated let telemetryRelay = AudioCaptureTelemetryRelay()

    #if canImport(ScreenCaptureKit)
    private let sampleQueue = DispatchQueue(label: "com.rajin.glossa.audio-samples")
    private var stream: SCStream?
    private var bufferCount = 0
    #endif

    func setMetricsHandler(_ handler: (@MainActor @Sendable (AudioCaptureMetrics) -> Void)?) {
        telemetryRelay.setHandler(handler)
    }

    func start(mode: CaptureMode) async throws {
        switch mode {
        case .systemAudio:
            try await startSystemAudio()
        case .microphone:
            throw AudioCaptureError.microphoneNotImplemented
        case .preview:
            throw AudioCaptureError.unsupportedMode
        }
    }

    func stop() async {
        #if canImport(ScreenCaptureKit)
        guard let stream else { return }
        self.stream = nil
        bufferCount = 0
        telemetryRelay.emit(.idle)
        try? await stream.stopCapture()
        #endif
    }

    private func startSystemAudio() async throws {
        #if canImport(ScreenCaptureKit)
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        guard let display = content.displays.first else {
            throw AudioCaptureError.noShareableDisplay
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = true
        configuration.sampleRate = 24_000
        configuration.channelCount = 1
        configuration.width = 2
        configuration.height = 2
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 1)

        bufferCount = 0
        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: sampleQueue)
        try await stream.startCapture()
        self.stream = stream
        #else
        throw AudioCaptureError.unsupportedMode
        #endif
    }
}

#if canImport(ScreenCaptureKit)
extension SystemAudioCaptureService: SCStreamDelegate, SCStreamOutput {
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        // The store will surface active start failures; runtime failures get telemetry next.
    }

    nonisolated func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .audio, sampleBuffer.isValid else { return }
        guard let metrics = AudioBufferAnalyzer.metrics(from: sampleBuffer) else { return }
        telemetryRelay.emit(metrics)
    }
}

private enum AudioBufferAnalyzer {
    static func metrics(from sampleBuffer: CMSampleBuffer) -> AudioCaptureMetrics? {
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
        let level = normalizedRMS(
            data: data,
            byteCount: byteCount,
            streamDescription: streamDescription
        )

        return AudioCaptureMetrics(
            level: level.rms,
            peak: level.peak,
            sampleCount: sampleCount,
            bufferCount: 1,
            sampleRate: streamDescription.mSampleRate,
            channelCount: Int(streamDescription.mChannelsPerFrame),
            lastUpdated: .now
        )
    }

    private static func normalizedRMS(
        data: UnsafeMutableRawPointer,
        byteCount: Int,
        streamDescription: AudioStreamBasicDescription
    ) -> (rms: Double, peak: Double) {
        let flags = streamDescription.mFormatFlags
        let isFloat = flags & kAudioFormatFlagIsFloat != 0
        let isSignedInteger = flags & kAudioFormatFlagIsSignedInteger != 0

        if isFloat && streamDescription.mBitsPerChannel == 32 {
            let values = data.assumingMemoryBound(to: Float.self)
            let count = max(1, byteCount / MemoryLayout<Float>.size)
            var sum = 0.0
            var peak = 0.0

            for index in 0..<count {
                let value = Double(values[index])
                let magnitude = min(1, abs(value))
                sum += magnitude * magnitude
                peak = max(peak, magnitude)
            }

            return (sqrt(sum / Double(count)), peak)
        }

        if isSignedInteger && streamDescription.mBitsPerChannel == 16 {
            let values = data.assumingMemoryBound(to: Int16.self)
            let count = max(1, byteCount / MemoryLayout<Int16>.size)
            var sum = 0.0
            var peak = 0.0

            for index in 0..<count {
                let value = Double(values[index]) / Double(Int16.max)
                let magnitude = min(1, abs(value))
                sum += magnitude * magnitude
                peak = max(peak, magnitude)
            }

            return (sqrt(sum / Double(count)), peak)
        }

        return (0, 0)
    }
}
#endif
