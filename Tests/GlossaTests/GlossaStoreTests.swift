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
        firstStore.overlayTextSize = .large
        firstStore.overlayScale = 0.72
        firstStore.overlayFontSize = 36
        firstStore.overlayFontStyle = .serif
        firstStore.overlayWidthFraction = 0.48
        firstStore.overlayBackgroundOpacity = 0.62
        firstStore.overlayCornerRadius = 24

        let restoredStore = GlossaStore(
            captureService: CaptureServiceSpy(),
            transcriptionService: DebugTranscriptionService(),
            defaults: defaults
        )

        XCTAssertFalse(restoredStore.showsSourceText)
        XCTAssertEqual(restoredStore.overlayTextSize, .large)
        XCTAssertEqual(restoredStore.overlayScale, 0.72, accuracy: 0.001)
        XCTAssertEqual(restoredStore.overlayFontSize, 36)
        XCTAssertEqual(restoredStore.overlayFontStyle, .serif)
        XCTAssertEqual(restoredStore.overlayWidthFraction, 0.48, accuracy: 0.001)
        XCTAssertEqual(restoredStore.overlayBackgroundOpacity, 0.62, accuracy: 0.001)
        XCTAssertEqual(restoredStore.overlayCornerRadius, 24)
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
