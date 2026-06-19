import Foundation

final class AudioCaptureTelemetryRelay: @unchecked Sendable {
    private let lock = NSLock()
    private var handler: (@MainActor @Sendable (AudioCaptureMetrics) -> Void)?

    func setHandler(_ handler: (@MainActor @Sendable (AudioCaptureMetrics) -> Void)?) {
        lock.lock()
        self.handler = handler
        lock.unlock()
    }

    func emit(_ metrics: AudioCaptureMetrics) {
        lock.lock()
        let handler = handler
        lock.unlock()

        guard let handler else { return }
        Task { @MainActor in
            handler(metrics)
        }
    }
}
