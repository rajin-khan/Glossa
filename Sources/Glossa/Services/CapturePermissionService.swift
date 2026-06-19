import Foundation

#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(CoreGraphics)
import CoreGraphics
#endif

@MainActor
final class CapturePermissionService {
    func snapshot() async -> CapturePermissionSnapshot {
        CapturePermissionSnapshot(
            screenRecording: screenRecordingState(),
            microphone: microphoneState(),
            checkedAt: .now
        )
    }

    func requestScreenRecording() async -> CapturePermissionSnapshot {
        #if canImport(CoreGraphics)
        _ = CGRequestScreenCaptureAccess()
        #endif
        return await snapshot()
    }

    func requestMicrophone() async -> CapturePermissionSnapshot {
        #if canImport(AVFoundation)
        _ = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
        #endif
        return await snapshot()
    }

    private func screenRecordingState() -> CapturePermissionState {
        #if canImport(CoreGraphics)
        CGPreflightScreenCaptureAccess() ? .granted : .needsPermission
        #else
        .unknown
        #endif
    }

    private func microphoneState() -> CapturePermissionState {
        #if canImport(AVFoundation)
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            .granted
        case .notDetermined:
            .needsPermission
        case .denied, .restricted:
            .denied
        @unknown default:
            .unknown
        }
        #else
        .unknown
        #endif
    }
}
