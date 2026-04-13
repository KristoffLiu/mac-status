import Cocoa
import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var viewModel: StatusViewModel?
    var timer: Timer?
    
    // Hosting controller for the popover content
    var popoverController: NSHostingController<MainPanelView>?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // App setup is now done in MacStatusApp, we just init the statusItem here
    }
    
    func setupMenuBar(viewModel: StatusViewModel) {
        self.viewModel = viewModel
        
        // NSStatusItem setup
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        // Setup popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 600)
        popover.behavior = .transient
        
        popoverController = NSHostingController(rootView: MainPanelView(viewModel: viewModel))
        popover.contentViewController = popoverController
        
        // Start a timer to redraw the image periodically based on the view model
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatusItemImage()
        }
        updateStatusItemImage()
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    private func updateStatusItemImage() {
        guard let viewModel = viewModel, let button = statusItem.button else { return }
        
        // Create the SwiftUI view for the menu bar
        let view = MenuBarLabelRendererView(viewModel: viewModel)
        
        // Render to Image
        let renderer = ImageRenderer(content: view)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
        renderer.isOpaque = false // Transparent background
        
        if let nsImage = renderer.nsImage {
            // Setting isTemplate to false allows us to show custom colors (green/red battery)
            nsImage.isTemplate = false
            button.image = nsImage
        }
    }
}
