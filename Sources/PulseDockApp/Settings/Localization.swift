import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese
    case english

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chinese: "中文"
        case .english: "English"
        }
    }
}

private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .chinese
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }
}

func localized(_ chinese: String, _ english: String, language: AppLanguage) -> String {
    switch language {
    case .chinese: chinese
    case .english: english
    }
}
