import SwiftUI
import Combine

struct AppWindowView: View {
    @State private var selectedTab: AppWindowTab? = .general
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    enum AppWindowTab: String, CaseIterable, Hashable {
        case general = "通用"
        // case dashboard = "状态看板"
        case menuBar = "菜单栏"
        case panels = "悬浮面板"
        case about = "关于"
        
        var icon: String {
            switch self {
            case .general: return "gearshape.fill"
            // case .dashboard: return "square.grid.2x2.fill"
            case .menuBar: return "menubar.rectangle"
            case .panels: return "macwindow.on.rectangle"
            case .about: return "info.circle.fill"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .general: return Color.gray
            // case .dashboard: return Color.blue
            case .menuBar: return Color.indigo
            case .panels: return Color.purple
            case .about: return Color(NSColor.darkGray)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(AppWindowTab.allCases, id: \.self, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label {
                        Text(LocalizedStringKey(tab.rawValue))
                    } icon: {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(tab.iconColor.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .shadow(color: .black.opacity(0.1), radius: 0.5, x: 0, y: 0.5)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 16) {
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        } detail: {
            Group {
                if let tab = selectedTab {
                    switch tab {
                    /*
                    case .dashboard:
                        DashboardView()
                    */
                    case .general:
                        GeneralSettingsView()
                    case .menuBar:
                        MenuBarSettingsView()
                    case .panels:
                        AppearanceSettingsView()
                    case .about:
                        AboutSettingsView()
                    }
                } else {
                    Text("Select a menu on the left")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(VisualEffectBackground(material: .windowBackground, blendingMode: .behindWindow))
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    AppWindowView()
}
