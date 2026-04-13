import Cocoa
import SwiftUI
import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var generatedMenuImage: NSImage? = nil
    var viewModel: StatusViewModel = StatusViewModel()
    var timer: Timer?
    
    override init() {
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start a timer to redraw the image periodically based on the view model
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatusItemImage()
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        // Initial draw
        Task { @MainActor in
            self.updateStatusItemImage()
        }
    }

    @MainActor
    private func updateStatusItemImage() {
        // Determine the system dark mode appearance and apply to the renderer 
        // to prevent Color.primary from collapsing to black in colored menu bar icons
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        
        let view = IsolatedBatteryGraphicRenderer(viewModel: viewModel)
            .environment(\.colorScheme, isDark ? .dark : .light)
        
        // Render to Image
        let renderer = ImageRenderer(content: view)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
        renderer.isOpaque = false // Transparent background
        
        if let nsImage = renderer.nsImage {
            // If the user wants a colored battery, it must be drawn fully transparent with colors.
            // If the user wants a monochrome battery, we can make it a template which automatically adapts to the system menu bar colors!
            let fillStyle = UserDefaults.standard.string(forKey: "batteryFillStyle") ?? "monochrome"
            if fillStyle == "status_color" {
                nsImage.isTemplate = false
            } else {
                nsImage.isTemplate = true
            }
            
            self.generatedMenuImage = nsImage
        }
    }
}
