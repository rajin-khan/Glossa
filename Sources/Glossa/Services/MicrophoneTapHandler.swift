import Foundation

#if canImport(ScreenCaptureKit)
import AVFoundation

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

final class MicrophoneTapHandler: @unchecked Sendable {
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

