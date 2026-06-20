import XCTest
@testable import Glossa

@MainActor
final class GlossaStoreTests: XCTestCase {
    func testChangingCaptureModeStopsAnActivePreview() {
        let defaults = makeDefaults()
        let store = GlossaStore(
            captureService: CaptureServiceSpy(),
            transcriptionService: DebugTranscriptionService(),
            defaults: defaults
        )

        store.captureMode = .preview
        store.startListening()
        XCTAssertEqual(store.listeningState, .previewing)

        store.captureMode = .microphone

        XCTAssertEqual(store.listeningState, .idle)
        XCTAssertTrue(store.overlayVisible)
        XCTAssertNil(store.currentSubtitle)
    }

    func testOverlayPreferencesPersist() {
        let defaults = makeDefaults()
        let firstStore = GlossaStore(
            captureService: CaptureServiceSpy(),
            transcriptionService: DebugTranscriptionService(),
            defaults: defaults
        )
        firstStore.showsSourceText = false
        firstStore.overlayScale = 0.72

        let restoredStore = GlossaStore(
            captureService: CaptureServiceSpy(),
            transcriptionService: DebugTranscriptionService(),
            defaults: defaults
        )

        XCTAssertFalse(restoredStore.showsSourceText)
        XCTAssertEqual(restoredStore.overlayScale, 0.72, accuracy: 0.001)
    }

    func testPreviewLaunchModeDoesNotReplaceSavedCaptureSource() {
        let defaults = makeDefaults()
        defaults.set(CaptureMode.systemAudio.rawValue, forKey: "captureMode")
        let store = GlossaStore(
            captureService: CaptureServiceSpy(),
            transcriptionService: DebugTranscriptionService(),
            defaults: defaults
        )

        store.handleLaunchArguments(["Glossa", "--preview-subtitles"])

        XCTAssertEqual(store.captureMode, .preview)
        XCTAssertEqual(defaults.string(forKey: "captureMode"), CaptureMode.systemAudio.rawValue)
        store.stopListening()
    }

    func testDynamicallyDiscoveredTargetLanguagePersists() {
        let defaults = makeDefaults()
        defaults.set("it", forKey: "targetLanguageCode")

        let store = GlossaStore(
            captureService: CaptureServiceSpy(),
            transcriptionService: DebugTranscriptionService(),
            defaults: defaults
        )

        XCTAssertEqual(store.targetLanguage.code, "it")
        XCTAssertFalse(store.targetLanguage.name.isEmpty)
        XCTAssertFalse(store.targetLanguage.nativeName.isEmpty)
    }

    func testScreenPermissionRequestOpensSettingsWhenAccessStillNeedsApproval() async {
        let permissionService = PermissionServiceSpy(
            snapshot: CapturePermissionSnapshot(
                screenRecording: .needsPermission,
                microphone: .granted,
                checkedAt: .now
            )
        )
        let systemApplicationService = SystemApplicationServiceSpy()
        let store = GlossaStore(
            captureService: CaptureServiceSpy(),
            permissionService: permissionService,
            systemApplicationService: systemApplicationService,
            transcriptionService: DebugTranscriptionService(),
            defaults: makeDefaults()
        )

        await store.requestScreenRecordingPermission()

        XCTAssertTrue(permissionService.didRequestScreenRecording)
        XCTAssertTrue(systemApplicationService.didOpenSystemAudioSettings)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "GlossaStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

@MainActor
private final class CaptureServiceSpy: AudioCaptureServing {
    func setMetricsHandler(_ handler: (@MainActor @Sendable (AudioCaptureMetrics) -> Void)?) { }
    func setFrameHandler(_ handler: (@MainActor @Sendable (AudioFrame) -> Void)?) { }
    func start(mode: CaptureMode) async throws { }
    func stop() async { }
}

@MainActor
private final class PermissionServiceSpy: CapturePermissionServing {
    private let currentSnapshot: CapturePermissionSnapshot
    private(set) var didRequestScreenRecording = false

    init(snapshot: CapturePermissionSnapshot) {
        currentSnapshot = snapshot
    }

    func snapshot() async -> CapturePermissionSnapshot {
        currentSnapshot
    }

    func requestScreenRecording() async -> CapturePermissionSnapshot {
        didRequestScreenRecording = true
        return currentSnapshot
    }

    func requestMicrophone() async -> CapturePermissionSnapshot {
        currentSnapshot
    }
}

@MainActor
private final class SystemApplicationServiceSpy: SystemApplicationServing {
    private(set) var didOpenSystemAudioSettings = false

    func openSystemAudioPermissionSettings() {
        didOpenSystemAudioSettings = true
    }

    func openMicrophonePermissionSettings() { }
    func restartApplication() { }
}
