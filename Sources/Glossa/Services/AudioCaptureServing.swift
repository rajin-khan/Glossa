import Foundation

@MainActor
protocol AudioCaptureServing: AnyObject {
    func setMetricsHandler(_ handler: (@MainActor @Sendable (AudioCaptureMetrics) -> Void)?)
    func start(mode: CaptureMode) async throws
    func stop() async
}

enum AudioCaptureError: LocalizedError {
    case microphoneNotImplemented
    case noShareableDisplay
    case unsupportedMode

    var errorDescription: String? {
        switch self {
        case .microphoneNotImplemented:
            "Microphone capture is planned, but this first milestone is focused on system audio."
        case .noShareableDisplay:
            "Glossa could not find a display for ScreenCaptureKit audio capture."
        case .unsupportedMode:
            "This capture mode is not available yet."
        }
    }
}
