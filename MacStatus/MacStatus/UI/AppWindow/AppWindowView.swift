import SwiftUI
import Combine

struct AppWindowView: View {
    @State private var selectedTab: AppWindowTab? = .dashboard
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    enum AppWindowTab: String, CaseIterable, Hashable {
        case dashboard = "仪表盘"
        case general = "通用"
        case menuBar = "菜单栏"
        case appearance = "外观"
        case about = "关于"
        
        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2.fill"
            case .general: return "gearshape"
            case .menuBar: return "menubar.rectangle"
            case .appearance: return "paintbrush"
            case .about: return "info.circle"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(AppWindowTab.allCases, id: \.self, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(LocalizedStringKey(tab.rawValue), systemImage: tab.icon)
                        .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 16) {
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        selectedTab = .general
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
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
                    case .dashboard:
                        DashboardView()
                    case .general:
                        GeneralSettingsView()
                    case .menuBar:
                        MenuBarSettingsView()
                    case .appearance:
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
