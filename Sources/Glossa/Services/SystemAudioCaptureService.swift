import Foundation

#if canImport(ScreenCaptureKit)
import CoreMedia
import ScreenCaptureKit
#endif

@MainActor
final class SystemAudioCaptureService: NSObject, AudioCaptureServing {
    #if canImport(ScreenCaptureKit)
    private let sampleQueue = DispatchQueue(label: "com.rajin.glossa.audio-samples")
    private var stream: SCStream?
    #endif

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
        // Next milestone: convert CMSampleBuffer into PCM frames for ASR providers.
    }
}
#endif
