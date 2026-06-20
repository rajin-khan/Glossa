import XCTest
@testable import Glossa

@MainActor
final class CaptureSessionCoordinatorTests: XCTestCase {
    func testRapidRestartDoesNotAllowAnOldStopToWin() async throws {
        let captureService = DelayedCaptureService()
        let coordinator = CaptureSessionCoordinator(
            captureService: captureService,
            permissionService: GrantedPermissionService()
        )
        var startCount = 0

        coordinator.start(
            mode: .microphone,
            permissionsUpdated: { _ in },
            didStart: { startCount += 1 },
            didFail: { _ in }
        )
        try await Task.sleep(for: .milliseconds(15))

        coordinator.stop()
        coordinator.start(
            mode: .microphone,
            permissionsUpdated: { _ in },
            didStart: { startCount += 1 },
            didFail: { _ in }
        )

        try await Task.sleep(for: .milliseconds(180))

        XCTAssertEqual(startCount, 1)
        XCTAssertEqual(captureService.events.last, "start.finished")
    }
}

@MainActor
private final class DelayedCaptureService: AudioCaptureServing {
    private(set) var events: [String] = []

    func setMetricsHandler(_ handler: (@MainActor @Sendable (AudioCaptureMetrics) -> Void)?) { }
    func setFrameHandler(_ handler: (@MainActor @Sendable (AudioFrame) -> Void)?) { }

    func start(mode: CaptureMode) async throws {
        events.append("start.began")
        try await Task.sleep(for: .milliseconds(60))
        events.append("start.finished")
    }

    func stop() async {
        events.append("stop")
        try? await Task.sleep(for: .milliseconds(10))
    }
}

@MainActor
private final class GrantedPermissionService: CapturePermissionServing {
    private let granted = CapturePermissionSnapshot(
        screenRecording: .granted,
        microphone: .granted,
        checkedAt: .now
    )

    func snapshot() async -> CapturePermissionSnapshot {
        granted
    }

    func requestScreenRecording() async -> CapturePermissionSnapshot {
        granted
    }

    func requestMicrophone() async -> CapturePermissionSnapshot {
        granted
    }
}
