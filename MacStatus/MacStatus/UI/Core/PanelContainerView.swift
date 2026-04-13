import SwiftUI

struct PanelContainerView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 8) {
            content
        }
        .padding(12)
        // Set width in points (400pt = 800 physical pixels on 2x Retina).
        .frame(width: 400)
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
