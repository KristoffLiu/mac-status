import SwiftUI
import UniformTypeIdentifiers

struct MainPanelView: View {
    @ObservedObject var viewModel: StatusViewModel
    @AppStorage("showPercentage") private var showPercentage = true
    @AppStorage("showWattage") private var showWattage = false
    @Environment(\.openWindow) private var openWindow
    
    @StateObject private var widgetManager = WidgetManager.shared
    @AppStorage("isPanelEditing") private var isEditing = false
    @State private var draggingItem: PanelWidget?

    var body: some View {
        PanelContainerView {
            // Header (App Title & Preferences)
            HStack {
                Text("MacStatus")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                
                Button(action: {
                    openWindow(id: "settings")
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isEditing.toggle()
                    }
                }) {
                    if isEditing {
                        Text("Done")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)
                    } else {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(isEditing ? .accentColor : .secondary)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
            
            // Unified Power & Battery Card
            VStack(spacing: 0) {
                ForEach(widgetManager.activeWidgets, id: \.self) { widget in
                    HStack(spacing: 0) {
                        if isEditing {
                            Button(action: {
                                widgetManager.remove(widget)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 8)
                            .padding(.trailing, 4)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                        
                        widgetContentView(for: widget)
                        
                        if isEditing {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.horizontal, 8)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, isEditing ? 6 : 0)
                    .background(isEditing ? Color(NSColor.windowBackgroundColor).opacity(0.8) : Color.clear)
                    .cornerRadius(isEditing ? 8 : 0)
                    .padding(.horizontal, isEditing ? 4 : 0)
                    .contentShape(Rectangle())
                    .onDrag {
                        self.draggingItem = widget
                        return NSItemProvider(object: widget.rawValue as NSString)
                    }
                    .onDrop(of: [UTType.text], delegate: WidgetDropDelegate(item: widget, activeWidgets: $widgetManager.activeWidgets, draggingItem: $draggingItem, manager: widgetManager))
                    
                    if widget != widgetManager.activeWidgets.last {
                        Divider()
                            .padding(.vertical, isEditing ? 4 : 12)
                            .padding(.horizontal, 12)
                            .opacity(isEditing ? 0.3 : 1)
                    }
                }
            }
            
            if isEditing {
                // Drawer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Widget")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                        
                    if widgetManager.inactiveWidgets.isEmpty {
                        Text("All widgets added")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(widgetManager.inactiveWidgets, id: \.self) { widget in
                            HStack {
                                Button(action: {
                                    widgetManager.add(widget)
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 16))
                                }
                                .buttonStyle(.plain)
                                
                                Text(LocalizedStringKey(widget.title))
                                    .font(.subheadline)
                                    .foregroundColor(.primary.opacity(0.8))
                                
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .cornerRadius(12)
                .padding(.top, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            EnergyEfficiencyManager.shared.appState = .active
        }
        .onDisappear {
            EnergyEfficiencyManager.shared.appState = .background
        }
    }
    
    @ViewBuilder
    private func widgetContentView(for widget: PanelWidget) -> some View {
        switch widget {
        case .powerFlow:
            SankeyPowerFlowView(powerFlow: viewModel.powerFlow)
        case .powerStatus:
            PowerStatusModule(batteryData: viewModel.batteryData, powerFlow: viewModel.powerFlow)
        case .batterySpecs:
            BatterySpecsModule(batteryData: viewModel.batteryData)
        case .batteryHealth:
            BatteryHealthModule(batteryData: viewModel.batteryData)
        case .highPowerApps:
            HighPowerAppsModule()
        case .systemMonitor:
            SystemMonitorModule()
        }
    }
}

#Preview {
    // 注入一个临时的 viewModel 供画布预览
    MainPanelView(viewModel: StatusViewModel())
}
