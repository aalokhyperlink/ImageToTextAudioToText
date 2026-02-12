import Foundation

struct TranslationLanguage: Identifiable, Hashable {
    let code: String
    let name: String

    var id: String { code }

    static let allOptions: [TranslationLanguage] = {
        let locale = Locale.current
        let codes = Set(Locale.isoLanguageCodes)

        return codes
            .filter { $0.count == 2 }
            .map { code in
                let languageName = locale.localizedString(forLanguageCode: code) ?? code.uppercased()
                return TranslationLanguage(code: code, name: languageName.capitalized)
            }
            .sorted { $0.name < $1.name }
    }()
}
