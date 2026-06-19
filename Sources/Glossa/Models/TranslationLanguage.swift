import Foundation

struct TranslationLanguage: Identifiable, Hashable {
    let code: String
    let name: String
    let nativeName: String

    var id: String { code }

    static let supported: [TranslationLanguage] = [
        .init(code: "en", name: "English", nativeName: "English"),
        .init(code: "bn", name: "Bangla", nativeName: "বাংলা"),
        .init(code: "es", name: "Spanish", nativeName: "Español"),
        .init(code: "fr", name: "French", nativeName: "Français"),
        .init(code: "de", name: "German", nativeName: "Deutsch"),
        .init(code: "ja", name: "Japanese", nativeName: "日本語"),
        .init(code: "ko", name: "Korean", nativeName: "한국어"),
        .init(code: "zh", name: "Chinese", nativeName: "中文"),
        .init(code: "hi", name: "Hindi", nativeName: "हिन्दी"),
        .init(code: "ar", name: "Arabic", nativeName: "العربية")
    ]
}
