import Foundation

@MainActor
final class CaptureSessionCoordinator {
    private let captureService: AudioCaptureServing
    private let permissionService: CapturePermissionServing
    private var operationTask: Task<Void, Never>?
    private var operationID = UUID()

    init(
        captureService: AudioCaptureServing,
        permissionService: CapturePermissionServing
    ) {
        self.captureService = captureService
        self.permissionService = permissionService
    }

    func setMetricsHandler(_ handler: (@MainActor @Sendable (AudioCaptureMetrics) -> Void)?) {
        captureService.setMetricsHandler(handler)
    }

    func setFrameHandler(_ handler: (@MainActor @Sendable (AudioFrame) -> Void)?) {
        captureService.setFrameHandler(handler)
    }

    func permissions() async -> CapturePermissionSnapshot {
        await permissionService.snapshot()
    }

    func requestScreenRecordingPermission() async -> CapturePermissionSnapshot {
        await permissionService.requestScreenRecording()
    }

    func requestMicrophonePermission() async -> CapturePermissionSnapshot {
        await permissionService.requestMicrophone()
    }

    func start(
        mode: CaptureMode,
        permissionsUpdated: @escaping @MainActor (CapturePermissionSnapshot) -> Void,
        didStart: @escaping @MainActor () -> Void,
        didFail: @escaping @MainActor (Error) -> Void
    ) {
        let previousTask = operationTask
        previousTask?.cancel()
        let currentID = UUID()
        operationID = currentID

        operationTask = Task { [weak self] in
            await previousTask?.value
            guard !Task.isCancelled, let self else { return }

            do {
                await captureService.stop()
                guard !Task.isCancelled else { return }

                var snapshot = await permissionService.snapshot()
                permissionsUpdated(snapshot)

                switch mode {
                case .systemAudio where !snapshot.screenRecording.isReady:
                    GlossaLog.capture.info("Requesting Screen Recording permission")
                    snapshot = await permissionService.requestScreenRecording()
                    permissionsUpdated(snapshot)
                    guard snapshot.screenRecording.isReady else {
                        throw AudioCaptureError.screenRecordingPermissionRequired
                    }
                case .microphone where !snapshot.microphone.isReady:
                    GlossaLog.capture.info("Requesting microphone permission")
                    snapshot = await permissionService.requestMicrophone()
                    permissionsUpdated(snapshot)
                    guard snapshot.microphone.isReady else {
                        throw AudioCaptureError.microphonePermissionRequired
                    }
                case .systemAudio, .microphone, .preview:
                    break
                }

                try await captureService.start(mode: mode)
                guard !Task.isCancelled else {
                    await captureService.stop()
                    return
                }
                didStart()
            } catch {
                guard !Task.isCancelled else { return }
                didFail(error)
            }

            finishOperation(id: currentID)
        }
    }

    func stop() {
        let previousTask = operationTask
        previousTask?.cancel()
        let currentID = UUID()
        operationID = currentID

        operationTask = Task { [weak self] in
            await previousTask?.value
            guard let self else { return }
            await captureService.stop()
            finishOperation(id: currentID)
        }
    }

    private func finishOperation(id: UUID) {
        guard operationID == id else { return }
        operationTask = nil
    }
}
