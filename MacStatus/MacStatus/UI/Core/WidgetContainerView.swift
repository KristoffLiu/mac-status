import SwiftUI

struct WidgetContainerView: View {
    let widget: WidgetID
    @EnvironmentObject private var viewModel: StatusViewModel
    @AppStorage(AppPreferenceKeys.powerFlowStyle) private var powerFlowStyle: PowerFlowStyle = .cards
    @State private var showSettings = false
    @State private var isHovering = false

    private var wantsEdgeToEdge: Bool {
        widget.wantsEdgeToEdge(powerFlowStyle: powerFlowStyle)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Content
            widget.content(viewModel: viewModel)
                // Shared content inset; modules do not add a second horizontal margin.
                .padding(.horizontal, wantsEdgeToEdge ? 0 : PanelLayout.contentInset)
                // Allow interactions inside the content view
                .zIndex(0)

            // Settings overlay
            if widget.hasSettings {
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
                .padding(.trailing, wantsEdgeToEdge ? 12 : 4)
                .opacity(isHovering || showSettings ? 1.0 : 0.0) // Keep visible when popover is open
                .popover(isPresented: $showSettings, arrowEdge: .trailing) {
                    if widget == .systemMonitor {
                        widget.settings
                            .presentationBackground(.ultraThinMaterial)
                    } else {
                        widget.settings.padding()
                    }
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
