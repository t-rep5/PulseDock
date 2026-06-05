import Darwin
import Foundation

final class SystemSampler: @unchecked Sendable {
    private var previousCPULoads: [processor_cpu_load_info]?
    private var previousProcessTimes: [Int32: UInt64] = [:]
    private var previousProcessSampleAt: Date?
    private var previousNetworkCounters: NetworkCounters?
    private var previousNetworkSampleAt: Date?
    private var dailyNetworkBaseline: NetworkCounters?
    private var dailyNetworkKey = SystemSampler.dayKey(for: Date())
    private var cachedDiskSnapshot = DiskSnapshot(readBytesPerSecond: 0, writeBytesPerSecond: 0)
    private var cachedDiskSampleAt: Date?
    private var cachedBatterySnapshot = BatterySnapshot(level: nil, isCharging: nil, powerSource: .unknown)
    private var cachedBatterySampleAt: Date?
    private let processorCount = max(1, ProcessInfo.processInfo.processorCount)
    private lazy var computerSnapshot = sampleComputer(totalMemoryBytes: physicalMemoryBytes())

    func sample() -> SystemSnapshot {
        let memory = sampleMemory()
        return SystemSnapshot(
            sampledAt: Date(),
            computer: currentComputerSnapshot(),
            cpuUsage: sampleCPUUsage(),
            loadAverage: sampleLoadAverage(),
            memory: memory,
            network: sampleNetwork(),
            disk: sampleDiskIfNeeded(),
            battery: sampleBatteryIfNeeded(),
            thermal: sampleThermal(),
            temperatures: sampleTemperatures(),
            gpu: sampleGPU(),
            fan: sampleFan(),
            processes: sampleProcesses()
        )
    }

    private func currentComputerSnapshot() -> ComputerSnapshot {
        var snapshot = computerSnapshot
        snapshot.uptimeSeconds = ProcessInfo.processInfo.systemUptime
        return snapshot
    }

    private func sampleComputer(totalMemoryBytes: UInt64) -> ComputerSnapshot {
        ComputerSnapshot(
            hostName: Host.current().localizedName ?? Host.current().name ?? "Mac",
            modelIdentifier: sysctlString("hw.model") ?? "Unknown",
            processorName: sysctlString("machdep.cpu.brand_string") ?? "Apple Silicon",
            physicalCoreCount: sysctlInt("hw.physicalcpu") ?? ProcessInfo.processInfo.processorCount,
            logicalCoreCount: sysctlInt("hw.logicalcpu") ?? ProcessInfo.processInfo.processorCount,
            memoryBytes: totalMemoryBytes,
            operatingSystemVersion: operatingSystemVersion(),
            operatingSystemBuild: operatingSystemBuild(),
            architecture: architectureName(),
            uptimeSeconds: ProcessInfo.processInfo.systemUptime
        )
    }

    private func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        let bytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sysctlInt(_ name: String) -> Int? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
        return Int(value)
    }

    private func operatingSystemVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    private func operatingSystemBuild() -> String {
        sysctlString("kern.osversion") ?? "Unknown"
    }

    private func architectureName() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "Unknown"
        #endif
    }

    private func sampleLoadAverage() -> LoadAverageSnapshot {
        var averages = [Double](repeating: 0, count: 3)
        let count = getloadavg(&averages, Int32(averages.count))
        guard count > 0 else {
            return LoadAverageSnapshot(oneMinute: 0, fiveMinutes: 0, fifteenMinutes: 0)
        }

        return LoadAverageSnapshot(
            oneMinute: averages[0],
            fiveMinutes: count > 1 ? averages[1] : 0,
            fifteenMinutes: count > 2 ? averages[2] : 0
        )
    }

    private func sampleMemory() -> MemorySnapshot {
        let totalBytes = physicalMemoryBytes()
        let pageSize = UInt64(getpagesize())
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemorySnapshot(
                usedBytes: 0,
                totalBytes: totalBytes,
                compressedBytes: 0,
                swapUsedBytes: sampleSwapUsedBytes() ?? 0,
                pressure: .unavailable
            )
        }

        let compressedBytes = UInt64(stats.compressor_page_count) * pageSize
        let appAndWiredBytes = UInt64(stats.active_count + stats.wire_count) * pageSize
        let usedBytes = min(totalBytes, appAndWiredBytes + compressedBytes)
        let swapUsedBytes = sampleSwapUsedBytes() ?? 0

        return MemorySnapshot(
            usedBytes: usedBytes,
            totalBytes: totalBytes,
            compressedBytes: compressedBytes,
            swapUsedBytes: swapUsedBytes,
            pressure: memoryPressure(usedBytes: usedBytes, totalBytes: totalBytes, compressedBytes: compressedBytes, swapUsedBytes: swapUsedBytes)
        )
    }

    private func physicalMemoryBytes() -> UInt64 {
        var memorySize: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        let result = sysctlbyname("hw.memsize", &memorySize, &size, nil, 0)
        return result == 0 ? memorySize : ProcessInfo.processInfo.physicalMemory
    }

    private func sampleSwapUsedBytes() -> UInt64? {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.stride
        let result = sysctlbyname("vm.swapusage", &usage, &size, nil, 0)
        guard result == 0 else { return nil }
        return usage.xsu_used
    }

    private func memoryPressure(usedBytes: UInt64, totalBytes: UInt64, compressedBytes: UInt64, swapUsedBytes: UInt64) -> MemoryPressure {
        guard totalBytes > 0 else { return .unavailable }

        let usedRatio = Double(usedBytes) / Double(totalBytes)
        if usedRatio >= 0.93 || swapUsedBytes > 2 * UInt64.gibibytes {
            return .critical
        }
        if usedRatio >= 0.85 || compressedBytes > UInt64.gibibytes || swapUsedBytes > 0 {
            return .warning
        }
        return .normal
    }

    private func sampleCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t?
        var processorCount: mach_msg_type_number_t = 0
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &cpuInfo,
            &infoCount
        )

        guard result == KERN_SUCCESS, let cpuInfo else {
            return 0
        }

        defer {
            let byteCount = vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), byteCount)
        }

        let loads = cpuInfo.withMemoryRebound(to: processor_cpu_load_info.self, capacity: Int(processorCount)) { buffer in
            (0..<Int(processorCount)).map { buffer[$0] }
        }

        guard let previousCPULoads, previousCPULoads.count == loads.count else {
            self.previousCPULoads = loads
            return 0
        }

        var busyTicks: UInt64 = 0
        var totalTicks: UInt64 = 0

        for index in loads.indices {
            let current = loads[index].cpu_ticks
            let previous = previousCPULoads[index].cpu_ticks

            let user = UInt64(current.0 - previous.0)
            let system = UInt64(current.1 - previous.1)
            let idle = UInt64(current.2 - previous.2)
            let nice = UInt64(current.3 - previous.3)

            busyTicks += user + system + nice
            totalTicks += user + system + idle + nice
        }

        self.previousCPULoads = loads
        guard totalTicks > 0 else { return 0 }
        return min(max(Double(busyTicks) / Double(totalTicks), 0), 1)
    }

    private func sampleProcesses() -> [ProcessSnapshot] {
        let now = Date()
        let elapsed = previousProcessSampleAt.map { now.timeIntervalSince($0) } ?? 0
        var nextProcessTimes: [Int32: UInt64] = [:]
        let psCPUPercentages = sampleProcessCPUPercentages()

        let summaries = processSummaries()
        let snapshots = summaries.compactMap { summary -> ProcessSnapshot? in
            let pid = summary.pid
            guard let usage = processUsage(summary: summary, sampledAt: now) else { return nil }

            nextProcessTimes[pid] = usage.cpuTimeNanoseconds
            let previousTime = previousProcessTimes[pid]
            let cpuUsage: Double
            if let psCPU = psCPUPercentages[pid] {
                cpuUsage = max(psCPU / 100, 0)
            } else if let previousTime, elapsed > 0, usage.cpuTimeNanoseconds >= previousTime {
                let deltaSeconds = Double(usage.cpuTimeNanoseconds - previousTime) / 1_000_000_000
                cpuUsage = max(deltaSeconds / elapsed / Double(processorCount), 0)
            } else {
                cpuUsage = 0
            }

            return ProcessSnapshot(
                pid: pid,
                parentPID: usage.parentPID,
                name: usage.name,
                cpuUsage: cpuUsage,
                memoryBytes: usage.residentBytes,
                threadCount: usage.threadCount,
                cpuTimeSeconds: Double(usage.cpuTimeNanoseconds) / 1_000_000_000,
                uptimeSeconds: usage.uptimeSeconds,
                state: usage.state,
                tag: tag(for: usage.name)
            )
        }

        previousProcessTimes = nextProcessTimes
        previousProcessSampleAt = now

        return snapshots
            .sorted {
                if $0.cpuUsage == $1.cpuUsage {
                    return $0.memoryBytes > $1.memoryBytes
                }
                return $0.cpuUsage > $1.cpuUsage
            }
            .prefix(60)
            .map { $0 }
    }

    private func sampleProcessCPUPercentages() -> [Int32: Double] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "pid=,pcpu="]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = nil

        do {
            try process.run()
        } catch {
            return [:]
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return [:] }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [:] }

        var percentages: [Int32: Double] = [:]
        for line in output.split(separator: "\n") {
            let parts = line.split(whereSeparator: \.isWhitespace)
            guard parts.count >= 2,
                  let pid = Int32(parts[0]),
                  let cpu = Double(parts[1]) else {
                continue
            }
            percentages[pid] = cpu
        }
        return percentages
    }

    private func sampleNetwork() -> NetworkSnapshot {
        let now = Date()
        guard let counters = networkCounters() else {
            return NetworkSnapshot(downloadBytesPerSecond: 0, uploadBytesPerSecond: 0, totalDownloadedBytes: 0, totalUploadedBytes: 0, todayDownloadedBytes: 0, todayUploadedBytes: 0)
        }

        resetDailyNetworkBaselineIfNeeded(now: now, counters: counters)

        defer {
            previousNetworkCounters = counters
            previousNetworkSampleAt = now
        }

        guard let previousNetworkCounters,
              let previousNetworkSampleAt else {
            return networkSnapshot(counters: counters, downloadBytesPerSecond: 0, uploadBytesPerSecond: 0)
        }

        let elapsed = now.timeIntervalSince(previousNetworkSampleAt)
        guard elapsed > 0 else {
            return networkSnapshot(counters: counters, downloadBytesPerSecond: 0, uploadBytesPerSecond: 0)
        }

        let receivedDelta = counters.receivedBytes >= previousNetworkCounters.receivedBytes ? counters.receivedBytes - previousNetworkCounters.receivedBytes : 0
        let sentDelta = counters.sentBytes >= previousNetworkCounters.sentBytes ? counters.sentBytes - previousNetworkCounters.sentBytes : 0

        return networkSnapshot(counters: counters, downloadBytesPerSecond: UInt64(Double(receivedDelta) / elapsed), uploadBytesPerSecond: UInt64(Double(sentDelta) / elapsed))
    }

    private func resetDailyNetworkBaselineIfNeeded(now: Date, counters: NetworkCounters) {
        let key = Self.dayKey(for: now)
        if dailyNetworkKey != key || dailyNetworkBaseline == nil {
            dailyNetworkKey = key
            dailyNetworkBaseline = counters
        }
    }

    private func networkSnapshot(counters: NetworkCounters, downloadBytesPerSecond: UInt64, uploadBytesPerSecond: UInt64) -> NetworkSnapshot {
        let baseline = dailyNetworkBaseline ?? counters
        let todayDownloadedBytes = counters.receivedBytes >= baseline.receivedBytes ? counters.receivedBytes - baseline.receivedBytes : 0
        let todayUploadedBytes = counters.sentBytes >= baseline.sentBytes ? counters.sentBytes - baseline.sentBytes : 0

        return NetworkSnapshot(
            downloadBytesPerSecond: downloadBytesPerSecond,
            uploadBytesPerSecond: uploadBytesPerSecond,
            totalDownloadedBytes: counters.receivedBytes,
            totalUploadedBytes: counters.sentBytes,
            todayDownloadedBytes: todayDownloadedBytes,
            todayUploadedBytes: todayUploadedBytes
        )
    }

    private static func dayKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private func networkCounters() -> NetworkCounters? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let interfaces else { return nil }
        defer { freeifaddrs(interfaces) }

        var receivedBytes: UInt64 = 0
        var sentBytes: UInt64 = 0
        var cursor: UnsafeMutablePointer<ifaddrs>? = interfaces

        while let interface = cursor?.pointee {
            defer { cursor = interface.ifa_next }

            let flags = Int32(interface.ifa_flags)
            guard flags & IFF_UP != 0,
                  flags & IFF_LOOPBACK == 0,
                  interface.ifa_data != nil else {
                continue
            }

            guard interface.ifa_addr.pointee.sa_family == UInt8(AF_LINK) else {
                continue
            }

            let data = interface.ifa_data.assumingMemoryBound(to: if_data.self).pointee
            receivedBytes += UInt64(data.ifi_ibytes)
            sentBytes += UInt64(data.ifi_obytes)
        }

        return NetworkCounters(receivedBytes: receivedBytes, sentBytes: sentBytes)
    }

    private func sampleDiskIfNeeded() -> DiskSnapshot {
        let now = Date()
        if let cachedDiskSampleAt,
           now.timeIntervalSince(cachedDiskSampleAt) < 10 {
            return cachedDiskSnapshot
        }

        cachedDiskSnapshot = sampleDisk()
        cachedDiskSampleAt = now
        return cachedDiskSnapshot
    }

    private func sampleDisk() -> DiskSnapshot {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/iostat")
        process.arguments = ["-d", "-w", "1", "-c", "2"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = nil

        do {
            try process.run()
        } catch {
            return DiskSnapshot(readBytesPerSecond: 0, writeBytesPerSecond: 0)
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            return DiskSnapshot(readBytesPerSecond: 0, writeBytesPerSecond: 0)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return DiskSnapshot(readBytesPerSecond: 0, writeBytesPerSecond: 0)
        }

        let lines = output
            .split(separator: "\n")
            .map(String.init)
            .filter { line in
                line.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
            }

        guard let latest = lines.last else {
            return DiskSnapshot(readBytesPerSecond: 0, writeBytesPerSecond: 0)
        }

        let values = latest
            .split(whereSeparator: \.isWhitespace)
            .compactMap { Double($0) }

        guard values.count >= 3 else {
            return DiskSnapshot(readBytesPerSecond: 0, writeBytesPerSecond: 0)
        }

        var totalMegabytesPerSecond: Double = 0
        var index = 2
        while index < values.count {
            totalMegabytesPerSecond += values[index]
            index += 3
        }

        let bytesPerSecond = UInt64(max(totalMegabytesPerSecond, 0) * 1_000_000)
        return DiskSnapshot(readBytesPerSecond: bytesPerSecond, writeBytesPerSecond: 0)
    }

    private func sampleBatteryIfNeeded() -> BatterySnapshot {
        let now = Date()
        if let cachedBatterySampleAt,
           now.timeIntervalSince(cachedBatterySampleAt) < 15 {
            return cachedBatterySnapshot
        }

        cachedBatterySnapshot = sampleBattery()
        cachedBatterySampleAt = now
        return cachedBatterySnapshot
    }

    private func sampleBattery() -> BatterySnapshot {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "batt"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = nil

        do {
            try process.run()
        } catch {
            return BatterySnapshot(level: nil, isCharging: nil, powerSource: .unknown)
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            return BatterySnapshot(level: nil, isCharging: nil, powerSource: .unknown)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return BatterySnapshot(level: nil, isCharging: nil, powerSource: .unknown)
        }

        let lowercasedOutput = output.lowercased()
        let powerSource: PowerSource
        if lowercasedOutput.contains("'battery power'") {
            powerSource = .battery
        } else if lowercasedOutput.contains("'ac power'") {
            powerSource = .acPower
        } else {
            powerSource = .unknown
        }

        let level = output
            .split(separator: "\n")
            .compactMap { line -> Double? in
                guard let percentRange = line.range(of: "%") else { return nil }
                let prefix = line[..<percentRange.lowerBound]
                let digits = prefix.reversed().prefix { $0.isNumber || $0 == "." }.reversed()
                guard let percentage = Double(String(digits)) else { return nil }
                return min(max(percentage / 100, 0), 1)
            }
            .first

        let isCharging: Bool?
        if lowercasedOutput.contains("discharging") || lowercasedOutput.contains("charged") {
            isCharging = false
        } else if lowercasedOutput.contains("charging") {
            isCharging = true
        } else {
            isCharging = nil
        }

        return BatterySnapshot(level: level, isCharging: isCharging, powerSource: powerSource)
    }

    private func sampleThermal() -> ThermalSnapshot {
        let state: ThermalState
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:
            state = .nominal
        case .fair:
            state = .fair
        case .serious:
            state = .serious
        case .critical:
            state = .critical
        @unknown default:
            state = .unknown
        }
        return ThermalSnapshot(state: state)
    }

    private func sampleTemperatures() -> TemperatureSnapshot {
        TemperatureSnapshot(cpuCelsius: nil, gpuCelsius: nil)
    }

    private func sampleGPU() -> GPUSnapshot {
        GPUSnapshot(usage: nil, temperatureCelsius: nil, memoryBytes: nil)
    }

    private func sampleFan() -> FanSnapshot {
        FanSnapshot(speedRPM: nil)
    }

    private func processSummaries() -> [ProcessSummary] {
        var mib = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var length = 0
        let lengthResult = mib.withUnsafeMutableBufferPointer { buffer in
            sysctl(buffer.baseAddress, u_int(buffer.count), nil, &length, nil, 0)
        }
        guard lengthResult == 0 else { return [] }

        let count = length / MemoryLayout<kinfo_proc>.stride
        var processes = Array(repeating: kinfo_proc(), count: count)
        let processResult = mib.withUnsafeMutableBufferPointer { mibBuffer in
            processes.withUnsafeMutableBufferPointer { processBuffer in
                sysctl(mibBuffer.baseAddress, u_int(mibBuffer.count), processBuffer.baseAddress, &length, nil, 0)
            }
        }
        guard processResult == 0 else { return [] }

        return processes.compactMap { process -> ProcessSummary? in
            let pid = process.kp_proc.p_pid
            guard pid > 0 else { return nil }

            let startTime = processStartDate(seconds: process.kp_proc.p_un.__p_starttime.tv_sec, microseconds: Int(process.kp_proc.p_un.__p_starttime.tv_usec))
            return ProcessSummary(
                pid: pid,
                parentPID: process.kp_eproc.e_ppid > 0 ? process.kp_eproc.e_ppid : nil,
                state: processState(process.kp_proc.p_stat),
                startTime: startTime
            )
        }
    }

    private func processUsage(summary: ProcessSummary, sampledAt: Date) -> ProcessUsage? {
        let pid = summary.pid
        var nameBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let nameLength = nameBuffer.withUnsafeMutableBufferPointer { buffer in
            proc_name(pid, buffer.baseAddress, UInt32(buffer.count))
        }
        guard nameLength > 0 else { return nil }

        let name = processName(from: nameBuffer)
        guard !name.isEmpty else { return nil }

        var info = rusage_info_v2()
        let result = withUnsafeMutablePointer(to: &info) { pointer -> Int32 in
            pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { reboundPointer in
                proc_pid_rusage(pid, RUSAGE_INFO_V2, reboundPointer)
            }
        }
        guard result == 0 else { return nil }

        return ProcessUsage(
            name: name,
            residentBytes: info.ri_resident_size,
            cpuTimeNanoseconds: info.ri_user_time + info.ri_system_time,
            parentPID: summary.parentPID,
            threadCount: processThreadCount(pid: pid),
            uptimeSeconds: summary.startTime.map { sampledAt.timeIntervalSince($0) },
            state: summary.state
        )
    }

    private func processThreadCount(pid: Int32) -> Int? {
        var taskInfo = proc_taskinfo()
        let byteCount = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, Int32(MemoryLayout<proc_taskinfo>.stride))
        guard byteCount == MemoryLayout<proc_taskinfo>.stride else { return nil }
        return Int(taskInfo.pti_threadnum)
    }

    private func processStartDate(seconds: Int, microseconds: Int) -> Date? {
        guard seconds > 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(seconds) + TimeInterval(microseconds) / 1_000_000)
    }

    private func processState(_ state: CChar) -> ProcessState {
        switch Int32(state) {
        case SRUN:
            return .running
        case SSLEEP:
            return .sleeping
        case SSTOP:
            return .stopped
        case SZOMB:
            return .zombie
        case SIDL:
            return .idle
        default:
            return .unknown
        }
    }

    private func tag(for processName: String) -> ProcessTag? {
        let name = processName.lowercased()

        if name.contains("windowserver") { return .system }
        if name.contains("intellij") || name == "idea" || name.contains("idea") { return .idea }
        if name == "java" || name.contains("java") { return .java }
        if name.contains("gradle") { return .gradle }
        if name.contains("maven") || name == "mvn" || name == "mvnw" { return .maven }
        if name.contains("xcode") { return .xcode }
        if name.contains("swift-frontend") || name.contains("swift-compile") { return .swiftCompiler }
        if name.contains("simulator") || name.contains("coresimulator") { return .simulator }
        if name.contains("docker") || name.contains("com.docker") { return .docker }
        if name == "node" || name.contains("node.js") || name.contains("node ") { return .node }
        if name.contains("chrome") || name.contains("google chrome") { return .chrome }
        if name.contains("codex") { return .codex }

        return nil
    }

    private func processName(from buffer: [CChar]) -> String {
        let bytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }
}

private struct ProcessUsage {
    var name: String
    var residentBytes: UInt64
    var cpuTimeNanoseconds: UInt64
    var parentPID: Int32?
    var threadCount: Int?
    var uptimeSeconds: TimeInterval?
    var state: ProcessState
}

private struct ProcessSummary {
    var pid: Int32
    var parentPID: Int32?
    var state: ProcessState
    var startTime: Date?
}

private struct NetworkCounters {
    var receivedBytes: UInt64
    var sentBytes: UInt64
}
