import Foundation

struct SystemSnapshot {
    var sampledAt: Date
    var computer: ComputerSnapshot
    var cpuUsage: Double
    var loadAverage: LoadAverageSnapshot
    var memory: MemorySnapshot
    var network: NetworkSnapshot
    var disk: DiskSnapshot
    var battery: BatterySnapshot
    var thermal: ThermalSnapshot
    var temperatures: TemperatureSnapshot
    var gpu: GPUSnapshot
    var fan: FanSnapshot
    var processes: [ProcessSnapshot]

    static let placeholder = SystemSnapshot(
        sampledAt: Date(),
        computer: ComputerSnapshot.placeholder,
        cpuUsage: 0.18,
        loadAverage: LoadAverageSnapshot(oneMinute: 0, fiveMinutes: 0, fifteenMinutes: 0),
        memory: MemorySnapshot(usedBytes: 12 * 1_024 * 1_024 * 1_024, totalBytes: 16 * 1_024 * 1_024 * 1_024, compressedBytes: 0, swapUsedBytes: 0, pressure: .normal),
        network: NetworkSnapshot(downloadBytesPerSecond: 0, uploadBytesPerSecond: 0, totalDownloadedBytes: 0, totalUploadedBytes: 0, todayDownloadedBytes: 0, todayUploadedBytes: 0),
        disk: DiskSnapshot(readBytesPerSecond: 0, writeBytesPerSecond: 0),
        battery: BatterySnapshot(level: nil, isCharging: nil, powerSource: .unknown),
        thermal: ThermalSnapshot(state: .nominal),
        temperatures: TemperatureSnapshot(cpuCelsius: nil, gpuCelsius: nil),
        gpu: GPUSnapshot(usage: nil, temperatureCelsius: nil, memoryBytes: nil),
        fan: FanSnapshot(speedRPM: nil),
        processes: []
    )
}

struct ComputerSnapshot {
    var hostName: String
    var modelIdentifier: String
    var processorName: String
    var physicalCoreCount: Int
    var logicalCoreCount: Int
    var memoryBytes: UInt64
    var operatingSystemVersion: String
    var operatingSystemBuild: String
    var architecture: String
    var uptimeSeconds: TimeInterval

    static let placeholder = ComputerSnapshot(
        hostName: "Mac",
        modelIdentifier: "Unknown",
        processorName: "Unknown",
        physicalCoreCount: ProcessInfo.processInfo.processorCount,
        logicalCoreCount: ProcessInfo.processInfo.processorCount,
        memoryBytes: ProcessInfo.processInfo.physicalMemory,
        operatingSystemVersion: ProcessInfo.processInfo.operatingSystemVersionString,
        operatingSystemBuild: "Unknown",
        architecture: "Unknown",
        uptimeSeconds: ProcessInfo.processInfo.systemUptime
    )
}

struct LoadAverageSnapshot {
    var oneMinute: Double
    var fiveMinutes: Double
    var fifteenMinutes: Double
}

struct MemorySnapshot {
    var usedBytes: UInt64
    var totalBytes: UInt64
    var compressedBytes: UInt64
    var swapUsedBytes: UInt64
    var pressure: MemoryPressure

    var usedRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }
}

enum MemoryPressure: String {
    case normal
    case warning
    case critical
    case unavailable
}

struct NetworkSnapshot {
    var downloadBytesPerSecond: UInt64
    var uploadBytesPerSecond: UInt64
    var totalDownloadedBytes: UInt64
    var totalUploadedBytes: UInt64
    var todayDownloadedBytes: UInt64
    var todayUploadedBytes: UInt64
}

struct DiskSnapshot {
    var readBytesPerSecond: UInt64
    var writeBytesPerSecond: UInt64

    var totalBytesPerSecond: UInt64 {
        readBytesPerSecond + writeBytesPerSecond
    }
}

struct BatterySnapshot {
    var level: Double?
    var isCharging: Bool?
    var powerSource: PowerSource
}

enum PowerSource: String {
    case battery
    case acPower
    case unknown
}

struct ThermalSnapshot {
    var state: ThermalState
}

struct TemperatureSnapshot {
    var cpuCelsius: Double?
    var gpuCelsius: Double?
}

struct GPUSnapshot {
    var usage: Double?
    var temperatureCelsius: Double?
    var memoryBytes: UInt64?
}

struct FanSnapshot {
    var speedRPM: Int?
}

enum ThermalState: String {
    case nominal
    case fair
    case serious
    case critical
    case unknown
}

struct ProcessSnapshot: Identifiable {
    var id: Int32 { pid }
    var pid: Int32
    var parentPID: Int32?
    var name: String
    var cpuUsage: Double
    var memoryBytes: UInt64
    var threadCount: Int?
    var cpuTimeSeconds: TimeInterval
    var uptimeSeconds: TimeInterval?
    var state: ProcessState
    var tag: ProcessTag?
}

enum ProcessState: String {
    case running
    case sleeping
    case stopped
    case zombie
    case idle
    case unknown
}

enum ProcessTag: String {
    case idea = "IDEA"
    case java = "Java"
    case gradle = "Gradle"
    case maven = "Maven"
    case xcode = "Xcode"
    case swiftCompiler = "Swift"
    case simulator = "Sim"
    case docker = "Docker"
    case node = "Node"
    case chrome = "Chrome"
    case codex = "Codex"
    case system = "SYS"
}

struct HistorySample: Codable, Identifiable {
    var id: Date { sampledAt }
    var sampledAt: Date
    var cpuUsage: Double
    var memoryUsage: Double
    var networkBytesPerSecond: UInt64
    var diskBytesPerSecond: UInt64

    init(snapshot: SystemSnapshot) {
        sampledAt = snapshot.sampledAt
        cpuUsage = snapshot.cpuUsage
        memoryUsage = snapshot.memory.usedRatio
        networkBytesPerSecond = snapshot.network.downloadBytesPerSecond + snapshot.network.uploadBytesPerSecond
        diskBytesPerSecond = snapshot.disk.totalBytesPerSecond
    }
}
