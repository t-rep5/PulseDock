import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var snapshot = SystemSnapshot.placeholder
    @Published private(set) var history: [HistorySample] = []
    @Published var settings = AppSettings.load()
    @Published var desktopSection: DesktopSection = .overview

    var onMenuBarUpdate: (() -> Void)?
    var onSettingsUpdate: (() -> Void)?

    private let sampler = SystemSampler()
    private let diagnosisEngine = DiagnosisEngine()
    private var timer: Timer?
    private let historyKey = "historySamples"
    private let samplerQueue = DispatchQueue(label: "com.pulsedock.sampler", qos: .utility)
    private var isSampling = false

    var diagnosis: Diagnosis {
        diagnosisEngine.evaluate(snapshot: snapshot, language: settings.language)
    }

    func start() {
        history = loadHistory()
        sample()
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func updateSettings(_ settings: AppSettings) {
        self.settings = settings
        settings.save()
        if settings.historyEnabled {
            trimHistory()
            saveHistory()
        } else {
            clearHistory()
        }
        onMenuBarUpdate?()
        onSettingsUpdate?()
        scheduleTimer()
    }

    func showDesktopSection(_ section: DesktopSection) {
        desktopSection = section
    }

    func clearHistory() {
        history = []
        AppSettings.clearLocalHistory()
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: settings.refreshInterval.seconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sample()
            }
        }
    }

    private func sample() {
        guard !isSampling else { return }
        isSampling = true

        let sampler = sampler
        samplerQueue.async { [weak self] in
            let nextSnapshot = sampler.sample()
            Task { @MainActor in
                guard let self else { return }
                self.snapshot = nextSnapshot
                self.recordHistory(snapshot: nextSnapshot)
                self.onMenuBarUpdate?()
                self.isSampling = false
            }
        }
    }

    private func recordHistory(snapshot: SystemSnapshot) {
        guard settings.historyEnabled else { return }
        history.append(HistorySample(snapshot: snapshot))
        trimHistory()
        saveHistory()
    }

    private func trimHistory() {
        let cutoff = Date().addingTimeInterval(-settings.historyRetention.seconds)
        history = history
            .filter { $0.sampledAt >= cutoff }
            .suffix(300)
            .map { $0 }
    }

    private func loadHistory() -> [HistorySample] {
        guard settings.historyEnabled,
              let data = UserDefaults.standard.data(forKey: historyKey),
              let samples = try? JSONDecoder().decode([HistorySample].self, from: data) else {
            return []
        }
        return samples.filter { $0.sampledAt >= Date().addingTimeInterval(-settings.historyRetention.seconds) }
    }

    private func saveHistory() {
        guard settings.historyEnabled,
              let data = try? JSONEncoder().encode(history) else {
            return
        }
        UserDefaults.standard.set(data, forKey: historyKey)
    }
}

extension HistoryRetention {
    var seconds: TimeInterval {
        switch self {
        case .oneDay:
            24 * 60 * 60
        case .sevenDays:
            7 * 24 * 60 * 60
        case .thirtyDays:
            30 * 24 * 60 * 60
        }
    }
}
