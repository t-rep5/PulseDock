import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var draft = AppSettings.load()
    @State private var showingPrivacyDetails = false

    private var language: AppLanguage {
        draft.language
    }

    var body: some View {
        Form {
            Section(localized("常规", "General", language: language)) {
                Picker(localized("语言", "Language", language: language), selection: $draft.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.label).tag(language)
                    }
                }

                Picker(localized("刷新频率", "Refresh Interval", language: language), selection: $draft.refreshInterval) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text(interval.label).tag(interval)
                    }
                }

                Picker(localized("菜单栏模式", "Menu Bar Mode", language: language), selection: $draft.menuBarMode) {
                    ForEach(MenuBarMode.allCases) { mode in
                        Text(mode.label(language: language)).tag(mode)
                    }
                }

                Toggle(localized("开机启动", "Launch at Login", language: language), isOn: $draft.launchAtLoginEnabled)
                    .disabled(true)
                Text(localized("开机启动底层逻辑暂未接入，后续会通过 macOS 登录项实现。", "Launch-at-login is not wired yet; it will use macOS login items later.", language: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(localized("历史记录", "History", language: language)) {
                Toggle(localized("保存本地历史记录", "Save Local History", language: language), isOn: $draft.historyEnabled)

                Picker(localized("历史保留时间", "Retention", language: language), selection: $draft.historyRetention) {
                    ForEach(HistoryRetention.allCases) { retention in
                        Text(retention.label(language: language)).tag(retention)
                    }
                }
                .disabled(!draft.historyEnabled)

                Button(localized("清除历史数据", "Clear History", language: language)) {
                    AppSettings.clearLocalHistory()
                }
                Text(localized("历史记录仅保存在本机；关闭历史后会停止写入本地趋势样本。", "History stays on this Mac; when disabled, PulseDock stops writing local trend samples.", language: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(localized("外观", "Appearance", language: language)) {
                Picker(localized("主题", "Theme", language: language), selection: $draft.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.label(language: language)).tag(theme)
                    }
                }

                Picker(localized("温度单位", "Temperature Unit", language: language), selection: $draft.temperatureUnit) {
                    ForEach(TemperatureUnit.allCases) { unit in
                        Text(unit.label(language: language)).tag(unit)
                    }
                }
            }

            Section(localized("隐私", "Privacy", language: language)) {
                DisclosureGroup(localized("隐私说明", "Privacy Notice", language: language), isExpanded: $showingPrivacyDetails) {
                    PrivacySummaryView(language: language)
                }

                Link(localized("打开系统隐私与安全设置", "Open Privacy & Security Settings", language: language), destination: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
            }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear {
            draft = appModel.settings
        }
        .onChange(of: draft) { newValue in
            appModel.updateSettings(newValue)
        }
    }
}

private struct PrivacySummaryView: View {
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
        .padding(.top, 4)
    }
}
