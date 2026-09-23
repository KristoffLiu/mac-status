import SwiftUI

enum PanelLayout {
    static let width: CGFloat = 400
    static let contentInset: CGFloat = 16
    static var maximumHeight: CGFloat {
        let screenHeight = NSScreen.screens.map { $0.visibleFrame.height }.min() ?? 800
        return min(640, screenHeight * 0.75)
    }
}

/// A soft break in the material, rather than a full-width rule between cards.
struct PanelSeparator: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.clear, .primary.opacity(0.09), .primary.opacity(0.09), .clear],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(height: 0.5)
            .accessibilityHidden(true)
    }
}

struct PanelContainerView<Content: View>: View {
    let content: Content
    @State private var contentHeight: CGFloat = PanelLayout.maximumHeight
    @State private var availableHeight = PanelLayout.maximumHeight

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 8) {
                content
            }
            .padding(.vertical, 12)
            .frame(width: PanelLayout.width)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        // A legacy, always-visible scroll bar otherwise steals width from the right edge.
        .scrollIndicators(.never)
        .scrollBounceBehavior(.basedOnSize)
        // Set width in points (400pt = 800 physical pixels on 2x Retina).
        .frame(width: PanelLayout.width, height: min(contentHeight, availableHeight))
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            availableHeight = PanelLayout.maximumHeight
        }
        // Apply Continuous Squircles to the container itself seamlessly
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// A base modifier for internal sub-cards
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        // AlDente style relies on individual nodes having backgrounds, not the whole container.
        content
            .padding(.vertical, 8)
    }
}

extension View {
    func moduleCardStyle() -> some View {
        self.modifier(CardModifier())
    }
}

#Preview {
    PanelContainerView {
        Text("Preview Content")
            .moduleCardStyle()
    }
}
