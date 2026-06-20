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

#endif
