import SwiftUI

struct WidgetContainerView: View {
    let plugin: any AppWidgetPlugin
    @State private var showSettings = false
    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Content
            plugin.contentView
                // By default apply the 12pt global panel margin, unless plugin requires full bleed
                .padding(.horizontal, plugin.wantsEdgeToEdge ? 0 : 12)
                // Allow interactions inside the content view
                .zIndex(0)

            // Settings overlay
            if plugin.hasSettings {
                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(5)
                        .background(
                            VisualEffectBackground(material: .popover, blendingMode: .behindWindow)
                                .clipShape(Circle())
                        )
                        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .padding(.trailing, plugin.wantsEdgeToEdge ? 12 : 4)
                .opacity(isHovering || showSettings ? 1.0 : 0.0) // Keep visible when popover is open
                .popover(isPresented: $showSettings, arrowEdge: .trailing) {
                    plugin.settingsView
                        .padding()
                }
                .zIndex(1)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isHovering = hovering
            }
        }
    }
}
