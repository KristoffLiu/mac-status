import Cocoa
import SwiftUI
import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var generatedMenuImage: NSImage? = nil
    var viewModel: StatusViewModel = StatusViewModel()
    var timer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start a timer to redraw the image periodically based on the view model
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatusItemImage()
        }
        updateStatusItemImage()
    }

    
        @MainActor
    private func updateStatusItemImage() {
        
        // Create the SwiftUI view for the menu bar
        let view = MenuBarLabelRendererView(viewModel: viewModel)
            .frame(height: 22) // Force a height for renderer
        
        // Render to Image
        let renderer = ImageRenderer(content: view)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
        renderer.isOpaque = false // Transparent background
        
        if let nsImage = renderer.nsImage {
            // Setting isTemplate to false allows us to show custom colors (green/red battery)
            nsImage.isTemplate = false
            self.generatedMenuImage = nsImage
        }
    }
}
