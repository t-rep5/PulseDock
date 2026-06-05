import Foundation

struct Diagnosis {
    var score: Int
    var status: HealthStatus
    var title: String
    var evidence: String
}

enum HealthStatus {
    case good
    case notice
    case poor
    case critical

    func label(language: AppLanguage) -> String {
        switch self {
        case .good: localized("状态良好", "Good", language: language)
        case .notice: localized("当前可用，但存在压力", "Usable, with pressure", language: language)
        case .poor: localized("明显性能压力", "Performance pressure", language: language)
        case .critical: localized("严重瓶颈", "Critical bottleneck", language: language)
        }
    }
}

struct DiagnosisEngine {
    func evaluate(snapshot: SystemSnapshot, language: AppLanguage) -> Diagnosis {
        let score = healthScore(for: snapshot)
        let status = status(for: score)
        let topProcess = snapshot.processes.first

        if snapshot.memory.swapUsedBytes > 2 * UInt64.gibibytes {
            return Diagnosis(
                score: score,
                status: status,
                title: localized("Swap 偏高，当前卡顿更可能来自内存压力。", "Swap is high; current slowdown is likely memory pressure.", language: language),
                evidence: "MEM \(snapshot.memory.usedRatio.percentText) · Swap \(snapshot.memory.swapUsedBytes.byteCount)"
            )
        }

        if snapshot.memory.pressure == .critical {
            return Diagnosis(
                score: score,
                status: status,
                title: localized("内存压力较高，系统正在积极回收内存。", "Memory pressure is high; macOS is actively reclaiming memory.", language: language),
                evidence: "Swap \(snapshot.memory.swapUsedBytes.byteCount) · Compressed \(snapshot.memory.compressedBytes.byteCount)"
            )
        }

        if snapshot.cpuUsage > 0.85 {
            return Diagnosis(
                score: score,
                status: status,
                title: localized("CPU 当前负载较高，前台操作可能会感觉变慢。", "CPU load is high; foreground work may feel slower.", language: language),
                evidence: "CPU \(snapshot.cpuUsage.percentText) · Top \(topProcessText(snapshot.processes))"
            )
        }

        if let topProcess, topProcess.cpuUsage > 0.25 {
            return Diagnosis(
                score: score,
                status: status,
                title: localized("\(topProcess.name) 正在占用较多 CPU。", "\(topProcess.name) is using notable CPU.", language: language),
                evidence: "Process \(topProcess.cpuUsage.percentText) · MEM \(topProcess.memoryBytes.byteCount)"
            )
        }

        if snapshot.memory.pressure == .warning || snapshot.memory.usedRatio > 0.80 {
            return Diagnosis(
                score: score,
                status: status,
                title: localized("内存偏紧，但尚未发现单一严重瓶颈。", "Memory is tight, but no single severe bottleneck is visible.", language: language),
                evidence: "MEM \(snapshot.memory.usedRatio.percentText) · Compressed \(snapshot.memory.compressedBytes.byteCount)"
            )
        }

        return Diagnosis(score: score, status: status, title: localized("未发现明显瓶颈", "No obvious bottleneck detected", language: language), evidence: "CPU \(snapshot.cpuUsage.percentText) · MEM \(snapshot.memory.usedRatio.percentText)")
    }

    private func topProcessText(_ processes: [ProcessSnapshot]) -> String {
        guard let process = processes.first else { return "unavailable" }
        return "\(process.name) \(process.cpuUsage.percentText)"
    }

    private func healthScore(for snapshot: SystemSnapshot) -> Int {
        var penalty = 0

        penalty += Int(min(snapshot.cpuUsage, 1.5) * 24)
        penalty += Int(min(max(snapshot.memory.usedRatio - 0.55, 0) / 0.45, 1) * 22)
        penalty += Int(min(Double(snapshot.memory.swapUsedBytes) / Double(6 * UInt64.gibibytes), 1) * 28)
        penalty += Int(min(Double(snapshot.memory.compressedBytes) / Double(max(snapshot.memory.totalBytes / 3, 1)), 1) * 14)

        switch snapshot.memory.pressure {
        case .critical:
            penalty += 16
        case .warning:
            penalty += 8
        case .normal, .unavailable:
            break
        }

        if let topProcess = snapshot.processes.first {
            penalty += Int(min(topProcess.cpuUsage, 1) * 10)
        }

        return min(max(100 - penalty, 0), 100)
    }

    private func status(for score: Int) -> HealthStatus {
        switch score {
        case 80...100:
            return .good
        case 60...79:
            return .notice
        case 30...59:
            return .poor
        default:
            return .critical
        }
    }
}

extension Double {
    var percentText: String {
        formatted(.percent.precision(.fractionLength(0)))
    }
}

extension UInt64 {
    var byteCount: String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .memory)
    }

    static var gibibytes: UInt64 {
        1_024 * 1_024 * 1_024
    }
}

extension PowerSource {
    func title(language: AppLanguage) -> String {
        switch self {
        case .battery:
            localized("电池供电", "Battery power", language: language)
        case .acPower:
            localized("电源供电", "AC power", language: language)
        case .unknown:
            localized("电源未知", "Power unknown", language: language)
        }
    }
}

extension ThermalState {
    func title(language: AppLanguage) -> String {
        switch self {
        case .nominal:
            localized("正常", "Nominal", language: language)
        case .fair:
            localized("轻微", "Fair", language: language)
        case .serious:
            localized("较高", "Serious", language: language)
        case .critical:
            localized("严重", "Critical", language: language)
        case .unknown:
            localized("未知", "Unknown", language: language)
        }
    }
}

extension ProcessState {
    func title(language: AppLanguage) -> String {
        switch self {
        case .running:
            localized("运行中", "Running", language: language)
        case .sleeping:
            localized("休眠", "Sleeping", language: language)
        case .stopped:
            localized("已停止", "Stopped", language: language)
        case .zombie:
            localized("僵尸", "Zombie", language: language)
        case .idle:
            localized("空闲", "Idle", language: language)
        case .unknown:
            localized("未知", "Unknown", language: language)
        }
    }

    func shortTitle(language: AppLanguage) -> String {
        switch self {
        case .running:
            localized("运行", "Run", language: language)
        case .sleeping:
            localized("休眠", "Sleep", language: language)
        case .stopped:
            localized("停止", "Stop", language: language)
        case .zombie:
            localized("僵尸", "Zombie", language: language)
        case .idle:
            localized("空闲", "Idle", language: language)
        case .unknown:
            localized("未知", "Unknown", language: language)
        }
    }
}

extension TimeInterval {
    func durationText(language: AppLanguage) -> String {
        let totalSeconds = max(Int(self), 0)
        let days = totalSeconds / 86_400
        let hours = (totalSeconds % 86_400) / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if days > 0 {
            return localized("\(days) 天 \(hours) 小时 \(minutes) 分钟 \(seconds) 秒", "\(days)d \(hours)h \(minutes)m \(seconds)s", language: language)
        }
        if hours > 0 {
            return localized("\(hours) 小时 \(minutes) 分钟", "\(hours)h \(minutes)m", language: language)
        }
        if minutes > 0 {
            return localized("\(minutes) 分钟 \(seconds) 秒", "\(minutes)m \(seconds)s", language: language)
        }
        return localized("\(seconds) 秒", "\(seconds)s", language: language)
    }
}

extension ComputerSnapshot {
    func uptimeText(language: AppLanguage) -> String {
        uptimeSeconds.durationText(language: language)
    }
}
