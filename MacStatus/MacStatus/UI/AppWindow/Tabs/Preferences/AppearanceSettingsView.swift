import SwiftUI

struct AppearanceSettingsView: View {
    @StateObject private var widgetManager = WidgetManager.shared
    @AppStorage(AppPreferenceKeys.isPanelEditing) private var isPanelEditing = false
    
    @AppStorage(AppPreferenceKeys.autoHidePanel) private var autoHidePanel = true
    @AppStorage(AppPreferenceKeys.enablePanelAnimations) private var enablePanelAnimations = true
    @AppStorage(AppPreferenceKeys.panelTheme) private var panelTheme = "system"
    
    var body: some View {
        Form {
            Section("全局面板行为") {
                Toggle("失去焦点时自动隐藏", isOn: $autoHidePanel)
                Toggle("平滑弹出动画", isOn: $enablePanelAnimations)
                Picker("面板主题", selection: $panelTheme) {
                    Text("跟随系统").tag("system")
                    Text("始终浅色").tag("light")
                    Text("始终深色").tag("dark")
                }
            }
            
            Section {
                List {
                    ForEach(widgetManager.activeWidgets, id: \.self) { widgetId in
                        WidgetRowView(widgetId: widgetId, isActive: true)
                    }
                    .onMove(perform: widgetManager.move)
                    
                    ForEach(widgetManager.inactiveWidgets, id: \.self) { widgetId in
                        WidgetRowView(widgetId: widgetId, isActive: false)
                    }
                }
                .frame(minHeight: 300)
            } header: {
                HStack {
                    Text("面板控制")
                    Spacer()
                    Button("呼出面板进行交互排布...") {
                        isPanelEditing = true
                        openMenuBarPanel()
                    }
                }
            } footer: {
                Text("可将系统模块控制配置为在面板中显示。拖拽可以进行排序。")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("悬浮面板")
    }
    
    private func openMenuBarPanel() {
        NotificationCenter.default.post(name: NSNotification.Name("OpenMenuBarPopover"), object: nil)
    }
}

struct WidgetRowView: View {
    let widgetId: String
    var isActive: Bool
    @StateObject private var widgetManager = WidgetManager.shared
    @State private var showingOptions = false
    
    var body: some View {
        if let widget = WidgetID(rawValue: widgetId) {
            HStack(spacing: 12) {
                Toggle("", isOn: Binding(
                    get: { isActive },
                    set: { newValue in
                        withAnimation {
                            if newValue {
                                widgetManager.add(widgetId)
                            } else {
                                widgetManager.remove(widgetId)
                            }
                        }
                    }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(widget.iconColor.opacity(0.2))
                    Image(systemName: widget.icon)
                        .foregroundColor(widget.iconColor)
                }
                .frame(width: 24, height: 24)
                
                Text(LocalizedStringKey(widget.name))
                
                Spacer()
                
                if widget.hasSettings {
                    Button {
                        showingOptions = true
                    } label: {
                        Text("\(widget.name) 选项...")
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text("无额外设置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                }
            }
            .padding(.vertical, 4)
            .sheet(isPresented: $showingOptions) {
                WidgetOptionsSheet(widget: widget)
            }
        }
    }
}

struct WidgetOptionsSheet: View {
    let widget: WidgetID
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Group {
            if widget.hasSettings {
                widget.settings
                    .contentMargins(.top, 16, for: .scrollIndicators)
                    .frame(maxHeight: 500)
            } else {
                VStack(spacing: 0) {
                    Form {
                        Text("暂无可用的自定义选项。")
                            .foregroundColor(.secondary)
                    }
                    .formStyle(.grouped)
                    .frame(width: 380)
                    
                    HStack {
                        Spacer()
                        Button("完成") {
                            dismiss()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    .padding()
                }
                .frame(minHeight: 200, maxHeight: 500)
            }
        }
    }
}
