import Foundation

@MainActor
protocol AudioCaptureServing: AnyObject {
    func setMetricsHandler(_ handler: (@MainActor @Sendable (AudioCaptureMetrics) -> Void)?)
    func setFrameHandler(_ handler: (@MainActor @Sendable (AudioFrame) -> Void)?)
    func start(mode: CaptureMode) async throws
    func stop() async
}

enum AudioCaptureError: LocalizedError {
    case microphoneNotImplemented
    case noShareableDisplay
    case screenRecordingPermissionRequired
    case microphonePermissionRequired
    case invalidMicrophoneInput
    case unsupportedMode

    var errorDescription: String? {
        switch self {
        case .microphoneNotImplemented:
            "Microphone capture is planned, but this first milestone is focused on system audio."
        case .noShareableDisplay:
            "Glossa could not find a display for ScreenCaptureKit audio capture."
        case .screenRecordingPermissionRequired:
            "Enable Glossa in Screen & System Audio Recording, then restart Glossa and start listening again."
        case .microphonePermissionRequired:
            "Microphone capture needs microphone permission. Grant it in the permission panel, then start listening again."
        case .invalidMicrophoneInput:
            "Glossa could not read a valid microphone input format from the current input device."
        case .unsupportedMode:
            "This capture mode is not available yet."
        }
    }
}
