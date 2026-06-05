import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appModel: AppModel
    private var language: AppLanguage { appModel.settings.language }

    var body: some View {
        VStack(spacing: 12) {
            HeaderView(language: language)
            HealthSummaryView(diagnosis: appModel.diagnosis)
            MetricsStripView(snapshot: appModel.snapshot)
            ProcessListView(processes: appModel.snapshot.processes, language: language)
            TrendsView(snapshot: appModel.snapshot, history: appModel.history, language: language)
            FooterView(refreshInterval: appModel.settings.refreshInterval, language: language)
        }
        .padding(16)
        .frame(width: 460, height: 600)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(DashboardPalette.panelStroke, lineWidth: 1)
                }
        }
    }
}

private struct HeaderView: View {
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 10) {
            PulseDockIconMark(size: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text("PulseDock")
                    .font(.system(size: 15, weight: .semibold))
                Text(localized("本地诊断", "Local diagnosis", language: language))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(DashboardPalette.good)
                    .frame(width: 7, height: 7)
                Text("2s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(DashboardPalette.tileFill, in: Capsule())

            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.borderless)
            .background(DashboardPalette.tileFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .frame(height: 38)
    }
}

private struct HealthSummaryView: View {
    let diagnosis: Diagnosis
    @Environment(\.appLanguage) private var language

    var body: some View {
        HStack(spacing: 14) {
            HealthRing(score: diagnosis.score, color: statusColor)

            VStack(alignment: .leading, spacing: 6) {
                Text(diagnosis.status.label(language: language))
                    .font(.system(size: 16, weight: .semibold))
                Text(diagnosis.title)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                DiagnosisBanner(evidence: diagnosis.evidence, color: statusColor)
            }
            Spacer()
        }
        .padding(12)
        .frame(height: 108)
        .background(DashboardPalette.cardFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DashboardPalette.panelStroke, lineWidth: 1)
        }
    }

    private var statusColor: Color {
        switch diagnosis.status {
        case .good: DashboardPalette.good
        case .notice: DashboardPalette.notice
        case .poor: DashboardPalette.poor
        case .critical: DashboardPalette.critical
        }
    }
}

private struct HealthRing: View {
    let score: Int
    let color: Color

    var progress: CGFloat {
        min(max(CGFloat(score) / 100, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.14), lineWidth: 9)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.28), radius: 8, y: 2)
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 34, weight: .semibold, design: .monospaced))
                Text("health")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 82, height: 82)
    }
}

private struct DiagnosisBanner: View {
    let evidence: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "scope")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(evidence)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(color.opacity(0.22), lineWidth: 1)
        }
    }
}

private struct MetricsStripView: View {
    let snapshot: SystemSnapshot

    var body: some View {
        HStack(spacing: 8) {
            metric("CPU", snapshot.cpuUsage.percentText, icon: "cpu", color: metricColor(snapshot.cpuUsage, warning: 0.65, critical: 0.85))
            metric("MEM", snapshot.memory.usedRatio.percentText, icon: "memorychip", color: metricColor(snapshot.memory.usedRatio, warning: 0.75, critical: 0.9))
            metric("NET", "↓\(snapshot.network.downloadBytesPerSecond.byteCount)", icon: "arrow.down.circle", color: DashboardPalette.info)
            metric("DISK", "\(snapshot.disk.readBytesPerSecond.byteCount)/s", icon: "internaldrive", color: DashboardPalette.poor)
        }
        .frame(height: 62)
    }

    private func metric(_ name: String, _ value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
                Text(name)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(DashboardPalette.tileFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(color.opacity(0.18), lineWidth: 1)
        }
    }

    private func metricColor(_ value: Double, warning: Double, critical: Double) -> Color {
        if value >= critical {
            return DashboardPalette.critical
        }
        if value >= warning {
            return DashboardPalette.notice
        }
        return DashboardPalette.good
    }
}

private struct ProcessListView: View {
    let processes: [ProcessSnapshot]
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(localized("Top 进程", "Top Processes", language: language))
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("CPU · MEM")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }

            if processes.isEmpty {
                EmptyProcessState(language: language)
            } else {
                VStack(spacing: 5) {
                    ForEach(Array(processes.prefix(5).enumerated()), id: \.element.id) { index, process in
                        ProcessRow(process: process, isHighlighted: index == 0)
                    }
                }
            }
        }
        .frame(height: 178, alignment: .top)
        .padding(10)
        .background(DashboardPalette.cardFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(DashboardPalette.panelStroke, lineWidth: 1)
        }
    }
}

private struct ProcessRow: View {
    let process: ProcessSnapshot
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: processIcon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isHighlighted ? DashboardPalette.info : .secondary)
                .frame(width: 18)

            Text(process.name)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 8)

            Text(process.cpuUsage.percentText)
                .frame(width: 42, alignment: .trailing)
            Text(process.memoryBytes.byteCount)
                .frame(width: 58, alignment: .trailing)

            Text(process.tag?.rawValue ?? "APP")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(tagColor)
                .frame(width: 42)
                .padding(.vertical, 3)
                .background(tagColor.opacity(0.12), in: Capsule())
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(isHighlighted ? DashboardPalette.info.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private var processIcon: String {
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

    private var tagColor: Color {
        switch process.tag {
        case .system: .secondary
        case nil: .secondary
        default: DashboardPalette.info
        }
    }
}

private struct EmptyProcessState: View {
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            Text(localized("暂无可显示进程", "No processes to show", language: language))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DashboardPalette.tileFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TrendsView: View {
    let snapshot: SystemSnapshot
    let history: [HistorySample]
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(localized("趋势", "Trends", language: language))
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("5 min")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                VStack(spacing: 4) {
                    TrendLine(values: cpuTrend, color: DashboardPalette.info)
                    TrendLine(values: memoryTrend, color: DashboardPalette.notice)
                }
                VStack(alignment: .leading, spacing: 6) {
                    trendLegend("CPU", snapshot.cpuUsage.percentText, color: DashboardPalette.info)
                    trendLegend("MEM", snapshot.memory.usedRatio.percentText, color: DashboardPalette.notice)
                    trendLegend("NET", "↓\(snapshot.network.downloadBytesPerSecond.byteCount)", color: DashboardPalette.good)
                }
                .frame(width: 96, alignment: .leading)
            }
        }
        .frame(height: 78)
        .padding(10)
        .background(DashboardPalette.cardFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(DashboardPalette.panelStroke, lineWidth: 1)
        }
    }

    private func trendLegend(_ name: String, _ value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(name)
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Text(value)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
    }

    private var cpuTrend: [Double] {
        trendValues(\.cpuUsage, fallback: snapshot.cpuUsage)
    }

    private var memoryTrend: [Double] {
        trendValues(\.memoryUsage, fallback: snapshot.memory.usedRatio)
    }

    private func trendValues(_ keyPath: KeyPath<HistorySample, Double>, fallback: Double) -> [Double] {
        let values = history.suffix(60).map { min(max($0[keyPath: keyPath], 0), 1) }
        return values.count > 1 ? values : [fallback, fallback]
    }
}

private struct TrendLine: View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DashboardPalette.tileFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct FooterView: View {
    let refreshInterval: RefreshInterval
    let language: AppLanguage

    var body: some View {
        HStack {
            Label(localized("仅本地", "Local only", language: language), systemImage: "lock")
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Label(localized("设置", "Settings", language: language), systemImage: "slider.horizontal.3")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            Text(localized("\(refreshInterval.label) 刷新", "\(refreshInterval.label) refresh", language: language))
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .frame(height: 20)
    }
}

private enum DashboardPalette {
    static let good = Color(red: 0.13, green: 0.77, blue: 0.37)
    static let notice = Color(red: 0.96, green: 0.62, blue: 0.04)
    static let poor = Color(red: 0.98, green: 0.45, blue: 0.09)
    static let critical = Color(red: 0.94, green: 0.27, blue: 0.27)
    static let info = Color(red: 0.23, green: 0.51, blue: 0.96)

    static let cardFill = Color(nsColor: .controlBackgroundColor).opacity(0.72)
    static let tileFill = Color(nsColor: .separatorColor).opacity(0.08)
    static let panelStroke = Color(nsColor: .separatorColor).opacity(0.34)
}
