import Foundation

enum CapturePermissionState: String, Sendable {
    case granted
    case needsPermission
    case denied
    case unknown

    var isReady: Bool {
        self == .granted
    }

    var label: String {
        switch self {
        case .granted:
            "Ready"
        case .needsPermission:
            "Needs Permission"
        case .denied:
            "Denied"
        case .unknown:
            "Unknown"
        }
    }
}

struct CapturePermissionSnapshot: Equatable, Sendable {
    var screenRecording: CapturePermissionState
    var microphone: CapturePermissionState
    var checkedAt: Date

    static let unknown = CapturePermissionSnapshot(
        screenRecording: .unknown,
        microphone: .unknown,
        checkedAt: .now
    )
}
