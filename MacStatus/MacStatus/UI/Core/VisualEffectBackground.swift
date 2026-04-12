import SwiftUI

struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// Global UI Constants
struct UIConstants {
    static let squircleRadius: CGFloat = 20.0
    
    struct Colors {
        static let chargingGreen = Color(NSColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0))
        static let dischargingBlue = Color(NSColor(red: 0.1, green: 0.5, blue: 0.9, alpha: 1.0))
        static let adapterAmber = Color(NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0))
        static let cardBackground = Color.black.opacity(0.1)
    }
}
