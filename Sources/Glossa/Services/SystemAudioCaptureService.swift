import Foundation

#if canImport(ScreenCaptureKit)
import AudioToolbox
import AVFoundation
import CoreMedia
import ScreenCaptureKit
#endif

@MainActor
final class SystemAudioCaptureService: NSObject, AudioCaptureServing {
    private nonisolated let telemetryRelay = AudioCaptureTelemetryRelay()
    private nonisolated let frameRelay = AudioFrameRelay()

    #if canImport(ScreenCaptureKit)
    private let sampleQueue = DispatchQueue(label: "com.rajin.glossa.audio-samples")
    private var stream: SCStream?
    private var audioEngine: AVAudioEngine?
    private var microphoneTapHandler: MicrophoneTapHandler?
    private var bufferCount = 0
    #endif

    func setMetricsHandler(_ handler: (@MainActor @Sendable (AudioCaptureMetrics) -> Void)?) {
        telemetryRelay.setHandler(handler)
    }

    func setFrameHandler(_ handler: (@MainActor @Sendable (AudioFrame) -> Void)?) {
        frameRelay.setHandler(handler)
    }

    func start(mode: CaptureMode) async throws {
        switch mode {
        case .systemAudio:
            try await startSystemAudio()
        case .microphone:
            try startMicrophone()
        case .preview:
            throw AudioCaptureError.unsupportedMode
        }
    }

    func stop() async {
        #if canImport(ScreenCaptureKit)
        stopMicrophone()
        guard let stream else { return }
        self.stream = nil
        bufferCount = 0
        telemetryRelay.emit(.idle)
        try? await stream.stopCapture()
        #endif
    }

    private func startSystemAudio() async throws {
        #if canImport(ScreenCaptureKit)
        GlossaLog.capture.info("Starting ScreenCaptureKit system audio")
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

    private func startMicrophone() throws {
        #if canImport(ScreenCaptureKit)
        GlossaLog.capture.info("Starting AVAudioEngine microphone capture")
        stopMicrophone()

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw AudioCaptureError.invalidMicrophoneInput
        }

        let tapHandler = MicrophoneTapHandler(
            telemetryRelay: telemetryRelay,
            frameRelay: frameRelay
        )

        GlossaLog.capture.info(
            "Microphone input format rate=\(format.sampleRate, privacy: .public) channels=\(format.channelCount, privacy: .public)"
        )

        inputNode.installTap(
            onBus: 0,
            bufferSize: 2_048,
            format: format,
            block: tapHandler.makeTapBlock()
        )

        engine.prepare()
        try engine.start()
        audioEngine = engine
        microphoneTapHandler = tapHandler
        #else
        throw AudioCaptureError.unsupportedMode
        #endif
    }

    private func stopMicrophone() {
        #if canImport(ScreenCaptureKit)
        guard let audioEngine else { return }
        microphoneTapHandler?.invalidate()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        self.audioEngine = nil
        microphoneTapHandler = nil
        #endif
    }
}

#if canImport(ScreenCaptureKit)
extension SystemAudioCaptureService: SCStreamDelegate, SCStreamOutput {
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        GlossaLog.capture.error("ScreenCaptureKit stopped: \(error.localizedDescription, privacy: .public)")
    }

    nonisolated func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .audio, sampleBuffer.isValid else { return }
        guard let analysis = AudioBufferAnalyzer.analysis(from: sampleBuffer) else { return }
        telemetryRelay.emit(analysis.metrics)
        frameRelay.emit(analysis.frame)
    }
}

private enum AudioBufferAnalyzer {
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

private final class AudioTapProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var hasLogged = false

    func recordFirstBuffer(frameLength: Int, hasAnalysis: Bool) {
        lock.lock()
        guard !hasLogged else {
            lock.unlock()
            return
        }
        hasLogged = true
        lock.unlock()

        GlossaLog.capture.info(
            "Received first microphone tap buffer frames=\(frameLength, privacy: .public) analyzed=\(hasAnalysis, privacy: .public)"
        )
    }
}

private final class MicrophoneTapHandler: @unchecked Sendable {
    private let telemetryRelay: AudioCaptureTelemetryRelay
    private let frameRelay: AudioFrameRelay
    private let tapProbe = AudioTapProbe()
    private let processingQueue = DispatchQueue(label: "com.rajin.glossa.microphone-processing", qos: .userInitiated)
    private let stateLock = NSLock()
    private var isActive = true

    init(telemetryRelay: AudioCaptureTelemetryRelay, frameRelay: AudioFrameRelay) {
        self.telemetryRelay = telemetryRelay
        self.frameRelay = frameRelay
    }

    func makeTapBlock() -> AVAudioNodeTapBlock {
        { [self] buffer, _ in
            receive(buffer)
        }
    }

    func invalidate() {
        stateLock.lock()
        isActive = false
        stateLock.unlock()
    }

    func receive(_ buffer: AVAudioPCMBuffer) {
        guard let batch = MicrophoneBufferAnalyzer.capture(from: buffer) else {
            return
        }

        processingQueue.async { [self] in
            guard isStillActive else { return }
            let analysis = MicrophoneBufferAnalyzer.analysis(from: batch)
            tapProbe.recordFirstBuffer(
                frameLength: batch.samples.count,
                hasAnalysis: analysis != nil
            )
            guard let analysis else { return }
            telemetryRelay.emit(analysis.metrics)
            frameRelay.emit(analysis.frame)
        }
    }

    private var isStillActive: Bool {
        stateLock.lock()
        let active = isActive
        stateLock.unlock()
        return active
    }
}
#endif
