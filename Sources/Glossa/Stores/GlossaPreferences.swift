import Foundation

struct GlossaPreferencesSnapshot {
    let targetLanguage: TranslationLanguage
    let captureMode: CaptureMode
    let transcriptionProvider: TranscriptionProviderKind
    let showsSourceText: Bool
    let overlayScale: Double
    let fallbackTranslationURLString: String
}

struct GlossaPreferences {
    private enum Key {
        static let targetLanguageCode = "targetLanguageCode"
        static let captureMode = "captureMode"
        static let transcriptionProvider = "transcriptionProvider"
        static let showsSourceText = "showsSourceText"
        static let overlayScale = "overlayScale"
        static let fallbackTranslationURL = "fallbackTranslationURL"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> GlossaPreferencesSnapshot {
        GlossaPreferencesSnapshot(
            targetLanguage: restoreTargetLanguage(),
            captureMode: restoreCaptureMode(),
            transcriptionProvider: restoreTranscriptionProvider(),
            showsSourceText: defaults.object(forKey: Key.showsSourceText) as? Bool ?? true,
            overlayScale: restoreDouble(
                key: Key.overlayScale,
                fallback: 1,
                range: OverlayLayoutMetrics.scaleRange
            ),
            fallbackTranslationURLString: defaults.string(forKey: Key.fallbackTranslationURL) ?? ""
        )
    }

    func saveTargetLanguage(_ language: TranslationLanguage) {
        defaults.set(language.code, forKey: Key.targetLanguageCode)
    }

    func saveCaptureMode(_ mode: CaptureMode) {
        defaults.set(mode.rawValue, forKey: Key.captureMode)
    }

    func saveTranscriptionProvider(_ provider: TranscriptionProviderKind) {
        defaults.set(provider.rawValue, forKey: Key.transcriptionProvider)
    }

    func saveShowsSourceText(_ showsSourceText: Bool) {
        defaults.set(showsSourceText, forKey: Key.showsSourceText)
    }

    func saveOverlayScale(_ scale: Double) {
        defaults.set(OverlayLayoutMetrics.clampedScale(scale), forKey: Key.overlayScale)
    }

    func saveFallbackTranslationURL(_ string: String) {
        defaults.set(string, forKey: Key.fallbackTranslationURL)
    }

    func withTransientCaptureMode(_ mode: CaptureMode, perform action: () -> Void) {
        let persistedMode = defaults.string(forKey: Key.captureMode)
        action()

        if let persistedMode {
            defaults.set(persistedMode, forKey: Key.captureMode)
        } else {
            defaults.removeObject(forKey: Key.captureMode)
        }
    }

    private func restoreTargetLanguage() -> TranslationLanguage {
        guard let code = defaults.string(forKey: Key.targetLanguageCode) else {
            return TranslationLanguage.supported[0]
        }

        return TranslationLanguage.supported.first(where: { $0.code == code })
            ?? TranslationLanguageCatalog.makeLanguage(identifier: code)
    }

    private func restoreCaptureMode() -> CaptureMode {
        guard let rawValue = defaults.string(forKey: Key.captureMode),
              let mode = CaptureMode(rawValue: rawValue)
        else {
            return .systemAudio
        }

        return mode
    }

    private func restoreTranscriptionProvider() -> TranscriptionProviderKind {
        guard let rawValue = defaults.string(forKey: Key.transcriptionProvider),
              let provider = TranscriptionProviderKind(rawValue: rawValue)
        else {
            return .whisperKit
        }

        return provider
    }

    private func restoreDouble(
        key: String,
        fallback: Double,
        range: ClosedRange<Double>
    ) -> Double {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return min(range.upperBound, max(range.lowerBound, defaults.double(forKey: key)))
    }
}
