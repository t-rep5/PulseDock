import Foundation

struct AppSettings: Equatable {
    var refreshInterval: RefreshInterval = .twoSeconds
    var menuBarMode: MenuBarMode = .compactMetrics
    var launchAtLoginEnabled = false
    var historyEnabled = true
    var historyRetention: HistoryRetention = .sevenDays
    var theme: AppTheme = .system
    var temperatureUnit: TemperatureUnit = .celsius
    var language: AppLanguage = .chinese

    static func load() -> AppSettings {
        AppSettings(
            refreshInterval: RefreshInterval(rawValue: UserDefaults.standard.string(forKey: "refreshInterval") ?? "") ?? .twoSeconds,
            menuBarMode: MenuBarMode(rawValue: UserDefaults.standard.string(forKey: "menuBarMode") ?? "") ?? .compactMetrics,
            launchAtLoginEnabled: UserDefaults.standard.object(forKey: "launchAtLoginEnabled") as? Bool ?? false,
            historyEnabled: UserDefaults.standard.object(forKey: "historyEnabled") as? Bool ?? true,
            historyRetention: HistoryRetention(rawValue: UserDefaults.standard.string(forKey: "historyRetention") ?? "") ?? .sevenDays,
            theme: AppTheme(rawValue: UserDefaults.standard.string(forKey: "theme") ?? "") ?? .system,
            temperatureUnit: TemperatureUnit(rawValue: UserDefaults.standard.string(forKey: "temperatureUnit") ?? "") ?? .celsius,
            language: AppLanguage(rawValue: UserDefaults.standard.string(forKey: "language") ?? "") ?? .chinese
        )
    }

    func save() {
        UserDefaults.standard.set(refreshInterval.rawValue, forKey: "refreshInterval")
        UserDefaults.standard.set(menuBarMode.rawValue, forKey: "menuBarMode")
        UserDefaults.standard.set(launchAtLoginEnabled, forKey: "launchAtLoginEnabled")
        UserDefaults.standard.set(historyEnabled, forKey: "historyEnabled")
        UserDefaults.standard.set(historyRetention.rawValue, forKey: "historyRetention")
        UserDefaults.standard.set(theme.rawValue, forKey: "theme")
        UserDefaults.standard.set(temperatureUnit.rawValue, forKey: "temperatureUnit")
        UserDefaults.standard.set(language.rawValue, forKey: "language")
    }

    static func clearLocalHistory() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "historySamples")
        defaults.removeObject(forKey: "historySnapshots")
        defaults.removeObject(forKey: "diagnosisHistory")
    }
}

enum RefreshInterval: String, CaseIterable, Identifiable {
    case oneSecond
    case twoSeconds
    case fiveSeconds

    var id: String { rawValue }

    var seconds: TimeInterval {
        switch self {
        case .oneSecond: 1
        case .twoSeconds: 2
        case .fiveSeconds: 5
        }
    }

    var label: String {
        switch self {
        case .oneSecond: "1s"
        case .twoSeconds: "2s"
        case .fiveSeconds: "5s"
        }
    }
}

enum MenuBarMode: String, CaseIterable, Identifiable {
    case iconOnly
    case compactMetrics
    case network
    case pressure

    var id: String { rawValue }

    func label(language: AppLanguage) -> String {
        switch self {
        case .iconOnly: localized("仅图标", "Icon Only", language: language)
        case .compactMetrics: localized("CPU + 内存", "CPU + Memory", language: language)
        case .network: localized("网络速率", "Network", language: language)
        case .pressure: localized("压力提示", "Pressure", language: language)
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    func label(language: AppLanguage) -> String {
        switch self {
        case .system: localized("跟随系统", "System", language: language)
        case .light: localized("浅色", "Light", language: language)
        case .dark: localized("深色", "Dark", language: language)
        }
    }
}

enum HistoryRetention: String, CaseIterable, Identifiable {
    case oneDay
    case sevenDays
    case thirtyDays

    var id: String { rawValue }

    func label(language: AppLanguage) -> String {
        switch self {
        case .oneDay: localized("1 天", "1 day", language: language)
        case .sevenDays: localized("7 天", "7 days", language: language)
        case .thirtyDays: localized("30 天", "30 days", language: language)
        }
    }
}

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius
    case fahrenheit

    var id: String { rawValue }

    func label(language: AppLanguage) -> String {
        switch self {
        case .celsius: localized("摄氏度", "Celsius", language: language)
        case .fahrenheit: localized("华氏度", "Fahrenheit", language: language)
        }
    }
}
