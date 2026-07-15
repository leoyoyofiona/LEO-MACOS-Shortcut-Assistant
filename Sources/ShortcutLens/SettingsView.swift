import AppKit
import SwiftUI

struct SettingsView: View {
    @AppStorage("panelPosition") private var panelPosition = PanelPosition.center.rawValue
    @AppStorage("displayLanguage") private var displayLanguage = DisplayLanguage.chinese.rawValue
    @AppStorage("triggerKey") private var triggerKey = TriggerKey.leftControl.rawValue
    let accessibilityGranted: Bool
    let inputMonitoringGranted: Bool
    let onRequestAccessibility: () -> Void
    let onRequestInputMonitoring: () -> Void

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 54, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(isChinese ? "LEO-MACOS快捷键助手正在运行" : "LEO-MACOS Shortcut Assistant is running")
                            .font(.title2.weight(.semibold))
                        Text(isChinese ? "切换到其他应用，按住设定的触发键显示快捷键，松开后隐藏。" : "Switch to another app. Hold your trigger key to show shortcuts; release to hide.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            Section(isChinese ? "显示语言" : "Display Language") {
                Picker(isChinese ? "语言" : "Language", selection: $displayLanguage) {
                    Text("中文").tag(DisplayLanguage.chinese.rawValue)
                    Text("English").tag(DisplayLanguage.english.rawValue)
                }
                .pickerStyle(.segmented)
            }

            Section(isChinese ? "触发方式" : "Trigger") {
                LabeledContent(isChinese ? "显示快捷键" : "Show shortcuts") {
                    Picker("", selection: $triggerKey) {
                        ForEach(TriggerKey.allCases) { key in
                            Text(isChinese ? key.chineseName : key.englishName).tag(key.rawValue)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 190)
                }
                Text(isChinese ? "按住选定按键显示面板，松开后立即隐藏。" : "Hold the selected key to show the panel; release to hide.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(isChinese ? "面板位置" : "Panel Position") {
                Picker(isChinese ? "显示位置" : "Position", selection: $panelPosition) {
                    ForEach(PanelPosition.allCases) { position in
                        Text(positionName(position)).tag(position.rawValue)
                    }
                }
            }

            Section(isChinese ? "系统权限" : "System Permissions") {
                HStack {
                    Label(
                        accessibilityGranted ? (isChinese ? "辅助功能权限已开启" : "Accessibility enabled") : (isChinese ? "需要辅助功能权限" : "Accessibility required"),
                        systemImage: accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(accessibilityGranted ? .green : .orange)
                    Spacer()
                    if !accessibilityGranted {
                        Button(isChinese ? "请求权限" : "Request", action: onRequestAccessibility)
                    }
                }
                HStack {
                    Label(
                        inputMonitoringGranted ? (isChinese ? "输入监控权限已开启" : "Input Monitoring enabled") : (isChinese ? "需要输入监控权限" : "Input Monitoring required"),
                        systemImage: inputMonitoringGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(inputMonitoringGranted ? .green : .orange)
                    Spacer()
                    if !inputMonitoringGranted {
                        Button(isChinese ? "请求权限" : "Request", action: onRequestInputMonitoring)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 620, height: 480)
    }

    private var isChinese: Bool {
        displayLanguage == DisplayLanguage.chinese.rawValue
    }

    private func positionName(_ position: PanelPosition) -> String {
        guard !isChinese else { return position.rawValue }
        switch position {
        case .center: return "Center"
        case .top: return "Top Center"
        case .topRight: return "Top Right"
        case .bottomRight: return "Bottom Right"
        }
    }
}
