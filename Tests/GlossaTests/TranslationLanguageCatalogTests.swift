import XCTest
@testable import Glossa

final class TranslationLanguageCatalogTests: XCTestCase {
    func testMergedCatalogKeepsBanglaWhenDynamicCatalogOmitsIt() {
        let dynamicLanguages = [
            TranslationLanguage(code: "en", name: "English", nativeName: "English"),
            TranslationLanguage(code: "fr", name: "French", nativeName: "Français")
        ]

        let merged = TranslationLanguageCatalog.mergedSupportedLanguages(dynamicLanguages: dynamicLanguages)

        XCTAssertTrue(merged.contains(where: { $0.code == "bn" && $0.nativeName == "বাংলা" }))
    }
}
