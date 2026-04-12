import SwiftUI

struct PanelContainerView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 16) {
            content
        }
        .padding(20)
        // Set fixed width for the popover
        .frame(width: 320)
        // Native MenuBarExtra popover already uses liquid glass when we don't force a background
        // Apply Continuous Squircles to the container itself if needed, but native popover already clips.
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
