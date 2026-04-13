import Cocoa
import SwiftUI
import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var viewModel: StatusViewModel = StatusViewModel()
    
    override init() {
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
    }
}
