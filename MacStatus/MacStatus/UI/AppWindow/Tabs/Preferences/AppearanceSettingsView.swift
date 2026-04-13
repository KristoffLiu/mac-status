import SwiftUI

struct AppearanceSettingsView: View {
    @StateObject private var widgetManager = WidgetManager.shared
    @AppStorage("isPanelEditing") private var isPanelEditing = false
    
    var body: some View {
        Form {
            Section {
                List {
                    ForEach(widgetManager.activeWidgets, id: \.self) { widget in
                        WidgetRowView(widget: widget, isActive: true)
                    }
                    .onMove(perform: widgetManager.move)
                    
                    ForEach(widgetManager.inactiveWidgets, id: \.self) { widget in
                        WidgetRowView(widget: widget, isActive: false)
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
        .navigationTitle("菜单栏与面板")
    }
    
    private func openMenuBarPanel() {
        NotificationCenter.default.post(name: NSNotification.Name("OpenMenuBarPopover"), object: nil)
    }
}

struct WidgetRowView: View {
    let widget: PanelWidget
    var isActive: Bool
    @StateObject private var widgetManager = WidgetManager.shared
    @State private var showingOptions = false
    
    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { isActive },
                set: { newValue in
                    withAnimation {
                        if newValue {
                            widgetManager.add(widget)
                        } else {
                            widgetManager.remove(widget)
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
            
            Text(LocalizedStringKey(widget.title))
            
            Spacer()
            
            Button {
                showingOptions = true
            } label: {
                Text("\(widget.title) 选项...")
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingOptions) {
            WidgetOptionsSheet(widget: widget)
        }
    }
}

struct WidgetOptionsSheet: View {
    let widget: PanelWidget
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Text("\(widget.title) 设置")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 8)
            if widget == .systemMonitor {
                SystemMonitorConfigView()
            } else {
                Form {
                    Text("暂无可用的自定义选项。")
                        .foregroundColor(.secondary)
                }
                .formStyle(.grouped)
            }
            
            HStack {
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(width: 380)
        .frame(minHeight: 200)
    }
}

struct SystemMonitorConfigView: View {
    @AppStorage("sysMonShowCompute") private var showCompute = true
    @AppStorage("sysMonShowMemory") private var showMemory = true
    @AppStorage("sysMonShowNetDisk") private var showNetDisk = true
    @AppStorage("sysMonSymmetricGraph") private var symmetricGraph = false
    
    var body: some View {
        Form {
            // 1. 预览区域
            Section {
                VStack {
                    SystemMonitorModule()
                }
                .frame(width: 320)
                .background(.regularMaterial)
                .cornerRadius(12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .center)
            } header: {
                Text("预览")
            }
            
            // 2. 显示设置
            Section("显示模块") {
                Toggle("计算 (CPU 与 GPU)", isOn: $showCompute)
                Toggle("统一内存", isOn: $showMemory)
                Toggle("网络与磁盘", isOn: $showNetDisk)
            }
            
            // 3. 图表样式
            Section("网络与磁盘图表样式") {
                Picker("走势图方向", selection: $symmetricGraph) {
                    Text("正向堆叠").tag(false)
                    Text("双向发散").tag(true)
                }
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
    }
}
