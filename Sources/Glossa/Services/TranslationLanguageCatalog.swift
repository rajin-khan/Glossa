import Foundation

#if canImport(Translation)
@preconcurrency import Translation
#endif

enum TranslationLanguageCatalog {
    @MainActor
    static func supportedLanguages() async -> [TranslationLanguage] {
        #if canImport(Translation)
        if #available(macOS 15.0, *) {
            let languages = await LanguageAvailability().supportedLanguages
            let mapped = languages.map { language in
                makeLanguage(identifier: language.minimalIdentifier)
            }
            let unique = Dictionary(mapped.map { ($0.code, $0) }, uniquingKeysWith: { first, _ in first })
            let sorted = unique.values.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            if !sorted.isEmpty {
                return sorted
            }
        }
        #endif

        return TranslationLanguage.supported
    }

    static func makeLanguage(identifier: String, displayLocale: Locale = .current) -> TranslationLanguage {
        let name = displayLocale.localizedString(forIdentifier: identifier)
            ?? displayLocale.localizedString(forLanguageCode: identifier)
            ?? identifier
        let nativeLocale = Locale(identifier: identifier)
        let nativeName = nativeLocale.localizedString(forIdentifier: identifier)
            ?? nativeLocale.localizedString(forLanguageCode: identifier)
            ?? name

        return TranslationLanguage(
            code: identifier,
            name: name.capitalized(with: displayLocale),
            nativeName: nativeName.capitalized(with: nativeLocale)
        )
    }
}
