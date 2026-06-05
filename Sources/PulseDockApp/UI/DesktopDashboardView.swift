import SwiftUI

struct DesktopDashboardView: View {
    @EnvironmentObject private var appModel: AppModel

    private var snapshot: SystemSnapshot { appModel.snapshot }
    private var diagnosis: Diagnosis { appModel.diagnosis }
    private var language: AppLanguage { appModel.settings.language }

    var body: some View {
        NavigationSplitView {
            DesktopSidebar(selection: $appModel.desktopSection, diagnosis: diagnosis, snapshot: snapshot, language: language)
        } detail: {
            Group {
                switch appModel.desktopSection {
                case .overview:
                    OverviewPage(snapshot: snapshot, diagnosis: diagnosis, language: language)
                case .processes:
                    ProcessesPage(processes: snapshot.processes, language: language)
                case .metrics:
                    MetricsPage(snapshot: snapshot, history: appModel.history, language: language)
                case .settings:
                    DesktopSettingsPage()
                        .environmentObject(appModel)
                case .about:
                    AboutPage(language: language)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(DesktopPalette.background)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 1280, minHeight: 780)
    }
}

enum DesktopSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case processes = "Processes"
    case metrics = "Metrics"
    case settings = "Settings"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: "gauge.with.dots.needle.67percent"
        case .processes: "list.bullet.rectangle"
        case .metrics: "chart.xyaxis.line"
        case .settings: "gearshape"
        case .about: "info.circle"
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .overview: localized("主页", "Overview", language: language)
        case .processes: localized("进程", "Processes", language: language)
        case .metrics: localized("指标", "Metrics", language: language)
        case .settings: localized("设置", "Settings", language: language)
        case .about: localized("关于", "About", language: language)
        }
    }
}

private struct DesktopSidebar: View {
    @Binding var selection: DesktopSection
    let diagnosis: Diagnosis
    let snapshot: SystemSnapshot
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                PulseDockIconMark(size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text("PulseDock")
                        .font(.system(size: 18, weight: .semibold))
                    Text(localized("本地诊断", "Local diagnosis", language: language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 6)

            VStack(spacing: 6) {
                ForEach(DesktopSection.allCases) { item in
                    Button {
                        selection = item
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: item.icon)
                                .frame(width: 18)
                            Text(item.title(language: language))
                            Spacer()
                        }
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                        .foregroundStyle(selection == item ? .primary : .secondary)
                        .background(selection == item ? DesktopPalette.selectedFill : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            SidebarHealthCard(diagnosis: diagnosis, snapshot: snapshot, language: language)

            Spacer()

            Text(localized("更新于 \(snapshot.sampledAt.formatted(date: .omitted, time: .standard))", "Updated \(snapshot.sampledAt.formatted(date: .omitted, time: .standard))", language: language))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(minWidth: 220)
        .background(DesktopPalette.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.35))
                .frame(width: 1)
        }
    }
}

private struct SidebarHealthCard: View {
    let diagnosis: Diagnosis
    let snapshot: SystemSnapshot
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(localized("健康", "Health", language: language))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(diagnosis.score)")
                    .font(.system(size: 34, weight: .semibold, design: .monospaced))
                Text("/100")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Text(diagnosis.status.label(language: language))
                .font(.system(size: 13, weight: .medium))
            Text("CPU \(snapshot.cpuUsage.percentText) · MEM \(snapshot.memory.usedRatio.percentText)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var color: Color {
        DesktopPalette.status(diagnosis.status)
    }
}

private struct OverviewPage: View {
    let snapshot: SystemSnapshot
    let diagnosis: Diagnosis
    let language: AppLanguage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PageHeader(
                    title: localized("主页", "Overview", language: language),
                    subtitle: localized("先判断当前压力来源，再查看关键指标和这台 Mac 的基础配置。", "Start with current pressure, then review key metrics and this Mac's system profile.", language: language)
                )

                OverviewStatusPanel(snapshot: snapshot, diagnosis: diagnosis, language: language)
                OverviewContextStrip(snapshot: snapshot, language: language)

                ComputerProfilePanel(computer: snapshot.computer, language: language)
            }
            .padding(22)
        }
    }
}

private struct OverviewStatusPanel: View {
    let snapshot: SystemSnapshot
    let diagnosis: Diagnosis
    let language: AppLanguage

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 14) {
                HealthSummaryPanel(diagnosis: diagnosis, snapshot: snapshot, language: language)
                EvidencePanel(snapshot: snapshot, language: language)
            }
            .frame(minWidth: 460, maxWidth: .infinity, alignment: .topLeading)

            ResourcePressurePanel(snapshot: snapshot, language: language)
                .frame(width: 430)
        }
    }
}

private struct ResourcePressurePanel: View {
    let snapshot: SystemSnapshot
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(localized("资源压力", "Resource Pressure", language: language), systemImage: "gauge.with.dots.needle.67percent")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text(snapshot.sampledAt.formatted(date: .omitted, time: .standard))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 11) {
                pressureRow(title: "CPU", value: snapshot.cpuUsage.percentText, progress: snapshot.cpuUsage, color: DesktopPalette.good, icon: "cpu")
                pressureRow(title: localized("内存", "Memory", language: language), value: snapshot.memory.usedRatio.percentText, progress: snapshot.memory.usedRatio, color: DesktopPalette.notice, icon: "memorychip")
                pressureRow(title: "Swap", value: snapshot.memory.swapUsedBytes.byteCount, progress: min(Double(snapshot.memory.swapUsedBytes) / Double(6 * UInt64.gibibytes), 1), color: DesktopPalette.critical, icon: "arrow.triangle.2.circlepath")
                pressureRow(title: localized("磁盘", "Disk", language: language), value: snapshot.disk.totalBytesPerSecond.byteCount + "/s", progress: nil, color: DesktopPalette.poor, icon: "internaldrive")
                pressureRow(title: localized("网络", "Network", language: language), value: (snapshot.network.downloadBytesPerSecond + snapshot.network.uploadBytesPerSecond).byteCount + "/s", progress: nil, color: DesktopPalette.info, icon: "network")
            }
        }
        .padding(16)
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func pressureRow(title: String, value: String, progress: Double?, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.14))
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * CGFloat(progress.map { min(max($0, 0), 1) } ?? 0.18))
                        .opacity(progress == nil ? 0.45 : 1)
                }
            }
            .frame(height: 6)
        }
    }
}

private struct OverviewContextStrip: View {
    let snapshot: SystemSnapshot
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 10) {
            contextItem(localized("热状态", "Thermal", language: language), snapshot.thermal.state.title(language: language), "thermometer.medium", DesktopPalette.notice)
            contextItem(localized("电源", "Power", language: language), snapshot.battery.powerSource.title(language: language), "bolt.fill", DesktopPalette.good)
            contextItem(localized("今日下载", "Today Down", language: language), snapshot.network.todayDownloadedBytes.byteCount, "arrow.down.circle", DesktopPalette.info)
            contextItem(localized("今日上传", "Today Up", language: language), snapshot.network.todayUploadedBytes.byteCount, "arrow.up.circle", DesktopPalette.good)
            contextItem(localized("风扇", "Fan", language: language), snapshot.fan.speedRPM.map { "\($0) RPM" } ?? localized("不可用", "N/A", language: language), "fan", DesktopPalette.info)
        }
    }

    private func contextItem(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ProcessesPage: View {
    let processes: [ProcessSnapshot]
    let language: AppLanguage
    @State private var searchText = ""
    @State private var selectedProcessID: Int32?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(title: localized("进程", "Processes", language: language), subtitle: localized("按名称浏览进程，并查看 CPU、内存、状态、线程和运行时长。", "Browse processes by name and inspect CPU, memory, state, threads, and uptime.", language: language))

            HStack(spacing: 10) {
                ProcessSummaryTile(title: localized("进程数", "Processes", language: language), value: "\(filteredProcesses.count)", subtitle: localized("当前列表", "current list", language: language), icon: "list.bullet.rectangle")
                ProcessSummaryTile(title: "CPU", value: topCPUText, subtitle: localized("列表最高", "highest in list", language: language), icon: "cpu")
                ProcessSummaryTile(title: localized("内存", "Memory", language: language), value: topMemoryText, subtitle: localized("列表最高", "highest in list", language: language), icon: "memorychip")
            }

            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(localized("搜索进程、PID 或标签", "Search process, PID, or tag", language: language), text: $searchText)
                    .textFieldStyle(.plain)
                Spacer()
                Text(localized("按名称正序", "Name A-Z", language: language))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(alignment: .top, spacing: 16) {
                ProcessTable(processes: filteredProcesses, selectedProcessID: $selectedProcessID, language: language)
                    .frame(minWidth: 650, maxWidth: .infinity)
                ProcessDetailPanel(process: selectedProcess, language: language)
                    .frame(width: 320)
            }
        }
        .padding(22)
        .onAppear {
            selectedProcessID = filteredProcesses.first?.pid
        }
        .onChange(of: processes.map(\.pid)) { _ in
            if selectedProcess == nil {
                selectedProcessID = filteredProcesses.first?.pid
            }
        }
    }

    private var filteredProcesses: [ProcessSnapshot] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = processes.filter { process in
            guard !query.isEmpty else { return true }
            return process.name.lowercased().contains(query)
                || "\(process.pid)".contains(query)
                || (process.tag?.rawValue.lowercased().contains(query) ?? false)
        }

        return filtered.sorted { lhs, rhs in
            let nameOrder = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
            if nameOrder == .orderedSame {
                return lhs.pid < rhs.pid
            }
            return nameOrder == .orderedAscending
        }
    }

    private var selectedProcess: ProcessSnapshot? {
        filteredProcesses.first { $0.pid == selectedProcessID } ?? filteredProcesses.first
    }

    private var topCPUText: String {
        filteredProcesses.max(by: { $0.cpuUsage < $1.cpuUsage })?.cpuUsage.percentText ?? "0%"
    }

    private var topMemoryText: String {
        filteredProcesses.max(by: { $0.memoryBytes < $1.memoryBytes })?.memoryBytes.byteCount ?? "0 KB"
    }
}

private struct ProcessSummaryTile: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(DesktopPalette.info)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MetricsPage: View {
    let snapshot: SystemSnapshot
    let history: [HistorySample]
    let language: AppLanguage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(title: localized("指标", "Metrics", language: language), subtitle: localized("按资源类型分组查看实时指标；系统没有开放的传感器会标明不可用。", "Grouped live metrics by resource type; unavailable sensors are labeled clearly.", language: language))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 10)], spacing: 10) {
                    MetricGroupCard(title: "CPU", icon: "cpu", color: DesktopPalette.good) {
                        MetricGroupRow(title: localized("使用率", "Usage", language: language), value: snapshot.cpuUsage.percentText, progress: snapshot.cpuUsage, color: DesktopPalette.good)
                        MetricGroupRow(title: localized("CPU 温度", "CPU Temperature", language: language), value: temperatureText(snapshot.temperatures.cpuCelsius), progress: nil, color: DesktopPalette.notice)
                        MetricGroupRow(title: localized("1 分钟负载", "1-Min Load", language: language), value: snapshot.loadAverage.oneMinute.formatted(.number.precision(.fractionLength(2))), progress: loadProgress(snapshot.loadAverage.oneMinute), color: DesktopPalette.info)
                    }

                    MetricGroupCard(title: "GPU", icon: "display", color: DesktopPalette.info) {
                        MetricGroupRow(title: localized("使用率", "Usage", language: language), value: optionalPercentText(snapshot.gpu.usage), progress: snapshot.gpu.usage, color: DesktopPalette.info)
                        MetricGroupRow(title: localized("GPU 温度", "GPU Temperature", language: language), value: temperatureText(snapshot.gpu.temperatureCelsius ?? snapshot.temperatures.gpuCelsius), progress: nil, color: DesktopPalette.notice)
                        MetricGroupRow(title: localized("显存占用", "VRAM", language: language), value: optionalByteText(snapshot.gpu.memoryBytes), progress: nil, color: DesktopPalette.poor)
                    }

                    MetricGroupCard(title: localized("主机", "Host", language: language), icon: "desktopcomputer", color: DesktopPalette.notice) {
                        MetricGroupRow(title: localized("内存占用", "Memory Used", language: language), value: snapshot.memory.usedBytes.byteCount, progress: snapshot.memory.usedRatio, color: DesktopPalette.notice)
                        MetricGroupRow(title: localized("压缩内存", "Compressed", language: language), value: snapshot.memory.compressedBytes.byteCount, progress: compressionProgress, color: DesktopPalette.poor)
                        MetricGroupRow(title: "Swap", value: snapshot.memory.swapUsedBytes.byteCount, progress: swapProgress, color: DesktopPalette.critical)
                        MetricGroupRow(title: localized("热压力", "Thermal State", language: language), value: snapshot.thermal.state.title(language: language), progress: nil, color: DesktopPalette.notice)
                    }

                    MetricGroupCard(title: localized("磁盘", "Disk", language: language), icon: "internaldrive", color: DesktopPalette.poor) {
                        MetricGroupRow(title: localized("读取", "Read", language: language), value: snapshot.disk.readBytesPerSecond.byteCount + "/s", progress: nil, color: DesktopPalette.info)
                        MetricGroupRow(title: localized("写入", "Write", language: language), value: snapshot.disk.writeBytesPerSecond == 0 ? unavailableText : snapshot.disk.writeBytesPerSecond.byteCount + "/s", progress: nil, color: DesktopPalette.poor)
                        MetricGroupRow(title: localized("总吞吐", "Total", language: language), value: snapshot.disk.totalBytesPerSecond.byteCount + "/s", progress: nil, color: DesktopPalette.good)
                    }

                    MetricGroupCard(title: localized("网络", "Network", language: language), icon: "network", color: DesktopPalette.info) {
                        MetricGroupRow(title: localized("下载", "Download", language: language), value: snapshot.network.downloadBytesPerSecond.byteCount + "/s", progress: nil, color: DesktopPalette.info)
                        MetricGroupRow(title: localized("上传", "Upload", language: language), value: snapshot.network.uploadBytesPerSecond.byteCount + "/s", progress: nil, color: DesktopPalette.good)
                        MetricGroupRow(title: localized("累计下载", "Total Down", language: language), value: snapshot.network.totalDownloadedBytes.byteCount, progress: nil, color: DesktopPalette.info)
                    }

                    MetricGroupCard(title: localized("流量统计", "Traffic", language: language), icon: "chart.bar", color: DesktopPalette.good) {
                        MetricGroupRow(title: localized("今日下载", "Today Down", language: language), value: snapshot.network.todayDownloadedBytes.byteCount, progress: nil, color: DesktopPalette.info)
                        MetricGroupRow(title: localized("今日上传", "Today Up", language: language), value: snapshot.network.todayUploadedBytes.byteCount, progress: nil, color: DesktopPalette.good)
                        MetricGroupRow(title: localized("累计上传", "Total Up", language: language), value: snapshot.network.totalUploadedBytes.byteCount, progress: nil, color: DesktopPalette.good)
                    }

                    MetricGroupCard(title: localized("风扇", "Fan", language: language), icon: "fan", color: DesktopPalette.info) {
                        MetricGroupRow(title: localized("转速", "Speed", language: language), value: fanSpeedText(snapshot.fan.speedRPM), progress: nil, color: DesktopPalette.info)
                        MetricGroupRow(title: localized("散热状态", "Cooling State", language: language), value: snapshot.thermal.state.title(language: language), progress: nil, color: DesktopPalette.notice)
                        MetricGroupRow(title: localized("传感器", "Sensor", language: language), value: snapshot.fan.speedRPM == nil ? unavailableText : localized("已连接", "Connected", language: language), progress: nil, color: DesktopPalette.good)
                    }

                    MetricGroupCard(title: localized("电池", "Battery", language: language), icon: "battery.75percent", color: DesktopPalette.good) {
                        MetricGroupRow(title: localized("电量", "Level", language: language), value: snapshot.battery.level?.percentText ?? unavailableText, progress: snapshot.battery.level, color: DesktopPalette.good)
                        MetricGroupRow(title: localized("电源", "Power", language: language), value: snapshot.battery.powerSource.title(language: language), progress: nil, color: DesktopPalette.info)
                        MetricGroupRow(title: localized("充电", "Charging", language: language), value: chargingText(snapshot.battery.isCharging), progress: nil, color: DesktopPalette.notice)
                    }
                }

                DesktopTrendPanel(snapshot: snapshot, history: history, language: language)
            }
            .padding(22)
        }
    }

    private var unavailableText: String {
        localized("不可用", "N/A", language: language)
    }

    private var compressionProgress: Double {
        min(Double(snapshot.memory.compressedBytes) / Double(max(snapshot.memory.totalBytes / 3, 1)), 1)
    }

    private var swapProgress: Double {
        min(Double(snapshot.memory.swapUsedBytes) / Double(6 * UInt64.gibibytes), 1)
    }

    private func loadProgress(_ load: Double) -> Double {
        min(max(load / Double(max(snapshot.computer.logicalCoreCount, 1)), 0), 1)
    }

    private func optionalPercentText(_ value: Double?) -> String {
        value?.percentText ?? unavailableText
    }

    private func optionalByteText(_ value: UInt64?) -> String {
        value?.byteCount ?? unavailableText
    }

    private func temperatureText(_ value: Double?) -> String {
        guard let value else { return unavailableText }
        return value.formatted(.number.precision(.fractionLength(1))) + " C"
    }

    private func fanSpeedText(_ value: Int?) -> String {
        guard let value else { return unavailableText }
        return "\(value) RPM"
    }

    private func chargingText(_ value: Bool?) -> String {
        switch value {
        case true:
            localized("正在充电", "Charging", language: language)
        case false:
            localized("未充电", "Not charging", language: language)
        case nil:
            unavailableText
        }
    }
}

private struct DenseMetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(value)
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MetricGroupCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 15)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }

            VStack(spacing: 0) {
                content
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MetricGroupRow: View {
    let title: String
    let value: String
    let progress: Double?
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 10)
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            if let progress {
                ProgressView(value: min(max(progress, 0), 1))
                    .tint(color)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 5)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.28)
        }
    }
}

private struct ComputerProfilePanel: View {
    let computer: ComputerSnapshot
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(localized("电脑配置", "Mac Profile", language: language))
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text(computer.architecture)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesktopPalette.selectedFill, in: Capsule())
            }

            HStack(spacing: 10) {
                profileHeroItem(localized("芯片 / CPU", "Chip / CPU", language: language), computer.processorName, "cpu", DesktopPalette.info)
                profileHeroItem(localized("统一内存", "Memory", language: language), computer.memoryBytes.byteCount, "memorychip", DesktopPalette.notice)
                profileHeroItem(localized("CPU 核心", "CPU Cores", language: language), localized("\(computer.physicalCoreCount)P / \(computer.logicalCoreCount)L", "\(computer.physicalCoreCount)P / \(computer.logicalCoreCount)L", language: language), "circle.grid.cross", DesktopPalette.good)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 0) {
                profileRow(localized("设备名称", "Host Name", language: language), computer.hostName, "desktopcomputer")
                profileRow(localized("机型标识", "Model", language: language), computer.modelIdentifier, "macbook")
                profileRow(localized("系统版本", "macOS", language: language), "macOS \(computer.operatingSystemVersion) (\(computer.operatingSystemBuild))", "apple.logo")
                profileRow(localized("运行时长", "Uptime", language: language), computer.uptimeText(language: language), "clock")
                profileRow(localized("架构", "Architecture", language: language), computer.architecture, "terminal")
                profileRow(localized("采样状态", "Sampling", language: language), localized("本机实时采集", "Local live sampling", language: language), "waveform.path.ecg")
            }
        }
        .padding(16)
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func profileHeroItem(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 15, weight: .semibold))
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .background(DesktopPalette.selectedFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func profileRow(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(DesktopPalette.info)
                .frame(width: 18)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 82, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 2)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.25)
        }
    }
}

private struct AboutPage: View {
    let language: AppLanguage

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 18) {
                VStack(spacing: 5) {
                    Text(localized("关于", "About", language: language))
                        .font(.system(size: 25, weight: .semibold))
                    Text(localized("PulseDock 是一个本地优先的 macOS 菜单栏性能监控工具。", "PulseDock is a local-first macOS menu bar performance monitor.", language: language))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .center, spacing: 16) {
                    VStack(spacing: 10) {
                        PulseDockIconMark(size: 56)
                        Text("PulseDock")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(localized("版本 0.1.0", "Version 0.1.0", language: language))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    aboutRow(localized("定位", "Purpose", language: language), localized("解释当前卡顿来源，并展示必要的 CPU、内存、磁盘、网络、进程和传感器指标。", "Explains current slowdowns and shows essential CPU, memory, disk, network, process, and sensor metrics.", language: language), "scope")
                    aboutRow(localized("运行方式", "Run Mode", language: language), localized("菜单栏常驻；打开桌面窗口时显示程序坞图标，关闭窗口后回到菜单栏模式。", "Stays in the menu bar; shows a Dock icon while the desktop window is open, then returns to menu bar mode after the window closes.", language: language), "menubar.dock.rectangle")
                    aboutRow(localized("隐私", "Privacy", language: language), localized("无账号、无遥测、无上传；性能数据只在本机采集和展示。", "No account, no telemetry, no upload; performance data is collected and shown locally.", language: language), "lock.shield")
                }
                .padding(16)
                .frame(maxWidth: 640, alignment: .center)
                .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(22)
            .frame(maxWidth: .infinity, minHeight: 560, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func aboutRow(_ title: String, _ body: String, _ icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(DesktopPalette.info)
                .frame(width: 24, height: 24)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.center)
            Text(body)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}
private struct DesktopSettingsPage: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var draft = AppSettings.load()
    @State private var showingPrivacyDetails = true
    @State private var selection: SettingsSection = .general

    private var language: AppLanguage { draft.language }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(
                    title: localized("设置", "Settings", language: language),
                    subtitle: localized("调整语言、刷新、菜单栏、历史记录和隐私选项。", "Adjust language, refresh, menu bar, history, and privacy options.", language: language)
                )

                HStack(alignment: .top, spacing: 16) {
                    SettingsSectionList(selection: $selection, language: language)
                        .frame(width: 190)

                    VStack(alignment: .leading, spacing: 0) {
                        SettingsContentHeader(section: selection, language: language)
                        Divider()

                        VStack(spacing: 0) {
                            switch selection {
                            case .general:
                                SettingsRow(title: localized("语言", "Language", language: language), detail: localized("切换桌面端和菜单栏文案。", "Switch desktop and menu bar copy.", language: language)) {
                                    Picker("", selection: $draft.language) {
                                        ForEach(AppLanguage.allCases) { language in
                                            Text(language.label).tag(language)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 150)
                                }

                                SettingsRow(title: localized("刷新频率", "Refresh Interval", language: language), detail: localized("采样越频繁，指标越实时。", "Higher frequency gives fresher metrics.", language: language)) {
                                    Picker("", selection: $draft.refreshInterval) {
                                        ForEach(RefreshInterval.allCases) { interval in
                                            Text(interval.label).tag(interval)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 110)
                                }

                                SettingsRow(title: localized("菜单栏模式", "Menu Bar Mode", language: language), detail: localized("控制常驻菜单栏显示内容。", "Controls what stays visible in the menu bar.", language: language)) {
                                    Picker("", selection: $draft.menuBarMode) {
                                        ForEach(MenuBarMode.allCases) { mode in
                                            Text(mode.label(language: language)).tag(mode)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 180)
                                }

                                SettingsRow(title: localized("开机启动", "Launch at Login", language: language), detail: localized("底层逻辑暂未接入，后续会通过 macOS 登录项实现。", "Not wired yet; this will use macOS login items later.", language: language)) {
                                    Toggle("", isOn: $draft.launchAtLoginEnabled)
                                        .labelsHidden()
                                        .disabled(true)
                                }

                            case .history:
                                SettingsRow(title: localized("保存本地历史记录", "Save Local History", language: language), detail: localized("历史记录只保存在本机，用于短期趋势。", "History stays on this Mac and powers short-term trends.", language: language)) {
                                    Toggle("", isOn: $draft.historyEnabled)
                                        .labelsHidden()
                                }

                                SettingsRow(title: localized("历史保留时间", "Retention", language: language), detail: localized("超过保留时间的趋势样本会被裁剪。", "Trend samples older than this are trimmed.", language: language)) {
                                    Picker("", selection: $draft.historyRetention) {
                                        ForEach(HistoryRetention.allCases) { retention in
                                            Text(retention.label(language: language)).tag(retention)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 130)
                                    .disabled(!draft.historyEnabled)
                                }

                                SettingsRow(title: localized("清除历史数据", "Clear History", language: language), detail: localized("立即移除本地趋势样本。", "Remove local trend samples immediately.", language: language)) {
                                    Button(role: .destructive) {
                                        appModel.clearHistory()
                                    } label: {
                                        Label(localized("清除", "Clear", language: language), systemImage: "trash")
                                    }
                                }

                            case .appearance:
                                SettingsRow(title: localized("主题", "Theme", language: language), detail: localized("当前版本跟随系统外观。", "Current version follows system appearance.", language: language)) {
                                    Picker("", selection: $draft.theme) {
                                        ForEach(AppTheme.allCases) { theme in
                                            Text(theme.label(language: language)).tag(theme)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 150)
                                }

                                SettingsRow(title: localized("温度单位", "Temperature Unit", language: language), detail: localized("用于后续温度指标显示。", "Used for future temperature metrics.", language: language)) {
                                    Picker("", selection: $draft.temperatureUnit) {
                                        ForEach(TemperatureUnit.allCases) { unit in
                                            Text(unit.label(language: language)).tag(unit)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 150)
                                }

                            case .privacy:
                                DisclosureGroup(localized("隐私说明", "Privacy Notice", language: language), isExpanded: $showingPrivacyDetails) {
                                    DesktopPrivacySummaryView(language: language)
                                        .padding(.top, 8)
                                }
                                .padding(16)

                                Divider()

                                SettingsRow(title: localized("系统隐私设置", "System Privacy Settings", language: language), detail: localized("打开 macOS 隐私与安全设置。", "Open macOS Privacy & Security settings.", language: language)) {
                                    Link(destination: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!) {
                                        Label(localized("打开", "Open", language: language), systemImage: "arrow.up.right.square")
                                    }
                                }
                            }
                        }
                    }
                    .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(maxWidth: 1120, alignment: .leading)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            draft = appModel.settings
        }
        .onChange(of: draft) { newValue in
            appModel.updateSettings(newValue)
        }
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case history
    case appearance
    case privacy

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .history: "clock.arrow.circlepath"
        case .appearance: "paintbrush"
        case .privacy: "lock.shield"
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .general: localized("常规", "General", language: language)
        case .history: localized("历史记录", "History", language: language)
        case .appearance: localized("外观", "Appearance", language: language)
        case .privacy: localized("隐私", "Privacy", language: language)
        }
    }

    func subtitle(language: AppLanguage) -> String {
        switch self {
        case .general: localized("语言、刷新和菜单栏", "Language, refresh, and menu bar", language: language)
        case .history: localized("本地趋势样本", "Local trend samples", language: language)
        case .appearance: localized("主题和单位", "Theme and units", language: language)
        case .privacy: localized("本地优先说明", "Local-first details", language: language)
        }
    }
}

private struct SettingsSectionList: View {
    @Binding var selection: SettingsSection
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 6) {
            ForEach(SettingsSection.allCases) { section in
                Button {
                    selection = section
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: section.icon)
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.title(language: language))
                                .font(.system(size: 13, weight: .semibold))
                            Text(section.subtitle(language: language))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .foregroundStyle(selection == section ? .primary : .secondary)
                    .background(selection == section ? DesktopPalette.selectedFill : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SettingsContentHeader: View {
    let section: SettingsSection
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: section.icon)
                .foregroundStyle(DesktopPalette.info)
                .frame(width: 26, height: 26)
                .background(DesktopPalette.selectedFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title(language: language))
                    .font(.system(size: 17, weight: .semibold))
                Text(section.subtitle(language: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }
}

private struct SettingsRow<Control: View>: View {
    let title: String
    let detail: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 20)
            control
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.45)
        }
    }
}

private struct DesktopPrivacySummaryView: View {
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized("PulseDock 只在本机采集性能诊断所需信息，例如 CPU、内存、磁盘、网络、温度状态和进程摘要。", "PulseDock only collects local performance data needed for diagnosis, such as CPU, memory, disk, network, thermal state, and process summaries.", language: language))
            Text(localized("PulseDock 不需要账号，不包含遥测，不上传性能数据，不做云同步，也不会把历史记录发送到远端服务。", "PulseDock does not require an account, has no telemetry, uploads no performance data, and does not sync history to remote services.", language: language))
            Text(localized("启用历史记录时，数据只应保存在本机；关闭历史记录或清除历史数据后，数据层应停止写入并移除本地历史。", "When history is enabled, data should stay local. Disabling or clearing history should stop local writes and remove stored history.", language: language))
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .textSelection(.enabled)
    }
}

private struct PageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 25, weight: .semibold))
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }
}

private struct HealthSummaryPanel: View {
    let diagnosis: Diagnosis
    let snapshot: SystemSnapshot
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.16), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(diagnosis.score) / 100)
                    .stroke(DesktopPalette.status(diagnosis.status), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(diagnosis.score)")
                        .font(.system(size: 38, weight: .semibold, design: .monospaced))
                    Text(localized("健康", "health", language: language))
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 106, height: 106)

            VStack(alignment: .leading, spacing: 8) {
                Text(diagnosis.status.label(language: language))
                    .font(.system(size: 17, weight: .semibold))
                Text(diagnosis.title)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(2)
                Text(diagnosis.evidence)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                Text("CPU \(snapshot.cpuUsage.percentText) · MEM \(snapshot.memory.usedRatio.percentText) · Swap \(snapshot.memory.swapUsedBytes.byteCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(minHeight: 132)
    }
}

private struct EvidencePanel: View {
    let snapshot: SystemSnapshot
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(localized("诊断依据", "Evidence", language: language), systemImage: "checklist.checked")
                .font(.system(size: 14, weight: .semibold))

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                evidence(localized("内存压力", "Memory pressure", language: language), snapshot.memory.pressure.rawValue, DesktopPalette.notice)
                evidence(localized("压缩内存", "Compressed", language: language), snapshot.memory.compressedBytes.byteCount, DesktopPalette.poor)
                evidence("Swap", snapshot.memory.swapUsedBytes.byteCount, DesktopPalette.critical)
                evidence(localized("最高进程", "Top process", language: language), snapshot.processes.first?.name ?? localized("不可用", "Unavailable", language: language), DesktopPalette.info)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func evidence(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3)
        }
        .background(DesktopPalette.selectedFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CompactMetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 19, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
    }
}

private struct ProcessPreview: View {
    let processes: [ProcessSnapshot]
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(localized("进程影响", "Process Impact", language: language))
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("Top 5")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            ForEach(processes.prefix(5)) { process in
                ProcessRowLine(process: process, language: language)
            }
        }
        .padding(16)
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ProcessTable: View {
    let processes: [ProcessSnapshot]
    @Binding var selectedProcessID: Int32?
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                tableHeader(localized("进程", "Process", language: language), width: nil, alignment: .leading)
                tableHeader("PID", width: 64, alignment: .trailing)
                tableHeader(localized("状态", "State", language: language), width: 64, alignment: .trailing)
                tableHeader("CPU", width: 66, alignment: .trailing)
                tableHeader(localized("内存", "Memory", language: language), width: 96, alignment: .trailing)
                tableHeader(localized("标签", "Tag", language: language), width: 66, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .frame(height: 34)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(processes.prefix(50)) { process in
                        Button {
                            selectedProcessID = process.pid
                        } label: {
                            ProcessRowLine(process: process, language: language, showPID: true)
                                .padding(.horizontal, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.plain)
                        .background(selectedProcessID == process.pid ? DesktopPalette.selectedFill : Color.clear)
                        .contentShape(Rectangle())
                        .focusable(false)
                        Divider().opacity(0.4)
                    }
                }
            }
        }
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private func tableHeader(_ title: String, width: CGFloat?, alignment: Alignment) -> some View {
        let text = Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

        if let width {
            text.frame(width: width, alignment: alignment)
        } else {
            text.frame(maxWidth: .infinity, alignment: alignment)
        }
    }
}

private struct ProcessDetailPanel: View {
    let process: ProcessSnapshot?
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let process {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: processIcon(for: process))
                            .foregroundStyle(DesktopPalette.info)
                            .frame(width: 36, height: 36)
                            .background(DesktopPalette.selectedFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(process.name)
                                .font(.system(size: 17, weight: .semibold))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text("PID \(process.pid) · \(process.state.title(language: language))")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(process.tag?.rawValue ?? "APP")
                            .font(.caption2.monospaced())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesktopPalette.selectedFill, in: Capsule())
                    }

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        detailMetric("CPU", process.cpuUsage.percentText, "cpu")
                        detailMetric(localized("内存", "Memory", language: language), process.memoryBytes.byteCount, "memorychip")
                        detailMetric(localized("线程", "Threads", language: language), process.threadCount.map(String.init) ?? unavailableText, "square.stack.3d.up")
                        detailMetric(localized("运行", "Uptime", language: language), process.uptimeSeconds?.durationText(language: language) ?? unavailableText, "clock")
                    }

                    VStack(spacing: 8) {
                        detailRow(localized("父进程", "Parent PID", language: language), process.parentPID.map(String.init) ?? unavailableText)
                        detailRow(localized("状态", "State", language: language), process.state.title(language: language))
                        detailRow(localized("累计 CPU", "CPU Time", language: language), process.cpuTimeSeconds.durationText(language: language))
                        detailRow(localized("进程标签", "Process Tag", language: language), process.tag?.rawValue ?? "APP")
                    }
                    .padding(10)
                    .background(DesktopPalette.selectedFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text(recommendation(for: process))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 26))
                        .foregroundStyle(.secondary)
                    Text(localized("没有匹配进程", "No Matching Process", language: language))
                        .font(.system(size: 14, weight: .semibold))
                    Text(localized("调整搜索条件后再查看详情。", "Adjust the search query to inspect details.", language: language))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Spacer()
        }
        .padding(16)
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var unavailableText: String {
        localized("不可用", "N/A", language: language)
    }

    private func detailMetric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(DesktopPalette.info)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
        .background(DesktopPalette.selectedFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
        }
        .font(.system(size: 13))
    }

    private func recommendation(for process: ProcessSnapshot) -> String {
        if process.cpuUsage > 0.5 {
            return localized("该进程 CPU 占用很高。优先确认它是否正在编译、索引、同步或执行长任务。", "This process is using high CPU. First check whether it is compiling, indexing, syncing, or running a long task.", language: language)
        }
        if process.memoryBytes > 2 * UInt64.gibibytes {
            return localized("该进程内存占用较高。如果系统同时出现 Swap 或压缩内存升高，它可能是卡顿来源之一。", "This process has high memory use. If swap or compressed memory is also rising, it may contribute to slowdown.", language: language)
        }
        return localized("当前没有明显异常。PulseDock 首版只提供低风险建议，不自动结束进程。", "No obvious anomaly right now. PulseDock's first version gives low-risk guidance and does not end processes automatically.", language: language)
    }

    private func processIcon(for process: ProcessSnapshot) -> String {
        switch process.tag {
        case .docker: "shippingbox"
        case .xcode, .swiftCompiler, .simulator: "hammer"
        case .chrome: "globe"
        case .java, .gradle, .maven, .idea: "terminal"
        case .node, .codex: "chevron.left.forwardslash.chevron.right"
        case .system: "gearshape.2"
        case nil: "app"
        }
    }
}

private struct DesktopTrendPanel: View {
    let snapshot: SystemSnapshot
    let history: [HistorySample]
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localized("短期趋势", "Short-Term Trends", language: language))
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text(localized("最近样本 \(history.count)", "\(history.count) samples", language: language))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                trendBlock(title: "CPU", value: snapshot.cpuUsage.percentText, values: trendValues(\.cpuUsage, fallback: snapshot.cpuUsage), color: DesktopPalette.info)
                trendBlock(title: localized("内存", "Memory", language: language), value: snapshot.memory.usedRatio.percentText, values: trendValues(\.memoryUsage, fallback: snapshot.memory.usedRatio), color: DesktopPalette.notice)
                trendBlock(title: localized("网络", "Network", language: language), value: (snapshot.network.downloadBytesPerSecond + snapshot.network.uploadBytesPerSecond).byteCount, values: scaledByteTrend(\.networkBytesPerSecond), color: DesktopPalette.good)
                trendBlock(title: localized("磁盘", "Disk", language: language), value: snapshot.disk.totalBytesPerSecond.byteCount, values: scaledByteTrend(\.diskBytesPerSecond), color: DesktopPalette.poor)
            }
        }
        .padding(16)
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func trendBlock(title: String, value: String, values: [Double], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.caption.monospacedDigit())
            }
            DesktopTrendLine(values: values, color: color)
                .frame(height: 62)
        }
        .frame(maxWidth: .infinity)
    }

    private func trendValues(_ keyPath: KeyPath<HistorySample, Double>, fallback: Double) -> [Double] {
        let values = history.suffix(90).map { min(max($0[keyPath: keyPath], 0), 1) }
        return values.count > 1 ? values : [fallback, fallback]
    }

    private func scaledByteTrend(_ keyPath: KeyPath<HistorySample, UInt64>) -> [Double] {
        let values = history.suffix(90).map { Double($0[keyPath: keyPath]) }
        guard let maximum = values.max(), maximum > 0 else { return [0, 0] }
        return values.map { min(max($0 / maximum, 0), 1) }
    }
}

private struct DesktopTrendLine: View {
    let values: [Double]
    let color: Color

    var body: some View {
        Canvas { context, size in
            let gridColor = Color.secondary.opacity(0.12)
            for step in 1...2 {
                let y = size.height * CGFloat(step) / 3
                var grid = Path()
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(grid, with: .color(gridColor), lineWidth: 1)
            }

            guard values.count > 1 else {
                return
            }

            var path = Path()
            for index in values.indices {
                let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
                let normalized = min(max(values[index], 0), 1)
                let y = size.height - (size.height * CGFloat(normalized))
                if index == values.startIndex {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .background(DesktopPalette.selectedFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ProcessRowLine: View {
    let process: ProcessSnapshot
    let language: AppLanguage
    var showPID = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(process.name)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            if showPID {
                Text("\(process.pid)")
                    .frame(width: 64, alignment: .trailing)
                    .foregroundStyle(.secondary)
            Text(process.state.shortTitle(language: language))
                .font(.caption2.monospaced())
                .frame(width: 64, alignment: .trailing)
                .foregroundStyle(process.state.color)
            }
            Text(process.cpuUsage.percentText)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .frame(width: 66, alignment: .trailing)
            Text(process.memoryBytes.byteCount)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(width: 96, alignment: .trailing)
            Text(process.tag?.rawValue ?? "APP")
                .font(.caption2.monospaced())
                .frame(width: 58, alignment: .center)
                .padding(.vertical, 4)
                .background(DesktopPalette.selectedFill, in: Capsule())
        }
        .frame(height: 38)
        .contentShape(Rectangle())
    }

    private var icon: String {
        switch process.tag {
        case .docker: "shippingbox"
        case .xcode, .swiftCompiler, .simulator: "hammer"
        case .chrome: "globe"
        case .java, .gradle, .maven, .idea: "terminal"
        case .node, .codex: "chevron.left.forwardslash.chevron.right"
        case .system: "gearshape.2"
        case nil: "app"
        }
    }
}

private extension ProcessState {
    var color: Color {
        switch self {
        case .running:
            DesktopPalette.good
        case .sleeping, .idle:
            .secondary
        case .stopped:
            DesktopPalette.notice
        case .zombie:
            DesktopPalette.critical
        case .unknown:
            DesktopPalette.info
        }
    }
}

private struct SignalPanel: View {
    let snapshot: SystemSnapshot
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localized("信号", "Signals", language: language))
                .font(.system(size: 16, weight: .semibold))
            signal("CPU", snapshot.cpuUsage, DesktopPalette.good)
            signal(localized("内存", "Memory", language: language), snapshot.memory.usedRatio, DesktopPalette.notice)
            signal("Swap", min(Double(snapshot.memory.swapUsedBytes) / Double(6 * UInt64.gibibytes), 1), DesktopPalette.critical)
            signal(localized("压缩内存", "Compressed", language: language), min(Double(snapshot.memory.compressedBytes) / Double(max(snapshot.memory.totalBytes / 3, 1)), 1), DesktopPalette.poor)
        }
        .padding(16)
        .background(DesktopPalette.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func signal(_ title: String, _ value: Double, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                Spacer()
                Text(value.percentText)
                    .monospacedDigit()
            }
            ProgressView(value: min(max(value, 0), 1))
                .tint(color)
        }
        .font(.system(size: 13, weight: .medium))
    }
}

private enum DesktopPalette {
    static let background = Color(nsColor: .windowBackgroundColor)
    static let sidebar = Color(nsColor: .controlBackgroundColor).opacity(0.58)
    static let panel = Color(nsColor: .controlBackgroundColor).opacity(0.82)
    static let selectedFill = Color(nsColor: .selectedContentBackgroundColor).opacity(0.16)

    static let good = Color(red: 0.13, green: 0.77, blue: 0.37)
    static let notice = Color(red: 0.96, green: 0.62, blue: 0.04)
    static let poor = Color(red: 0.98, green: 0.45, blue: 0.09)
    static let critical = Color(red: 0.94, green: 0.27, blue: 0.27)
    static let info = Color(red: 0.23, green: 0.51, blue: 0.96)

    static func status(_ status: HealthStatus) -> Color {
        switch status {
        case .good: good
        case .notice: notice
        case .poor: poor
        case .critical: critical
        }
    }
}
