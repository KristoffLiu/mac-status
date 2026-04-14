import Foundation
import Combine
import AppKit

struct AppEnergyImpact: Identifiable {
    let id = UUID()
    let pid: Int32?
    let name: String
    let power: Double
    let icon: NSImage?
}

class HighPowerAppsService: ObservableObject {
    static let shared = HighPowerAppsService()
    
    @Published var highPowerApps: [AppEnergyImpact] = []
    
    private var timerCancellable: AnyCancellable?
    private var lastFetchTime = Date.distantPast
    
    private init() {
        startPolling()
    }
    
    func startPolling() {
        timerCancellable = EnergyEfficiencyManager.shared.tickPublisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                let now = Date()
                let intervalToWait = EnergyEfficiencyManager.shared.appState == .active ? 8.0 : 30.0
                if now.timeIntervalSince(self.lastFetchTime) >= intervalToWait {
                    self.lastFetchTime = now
                    self.fetchTopApps()
                }
            }
        
        // Initial fetch
        fetchTopApps()
    }
    
    private func fetchTopApps() {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/top")
            // -l 2: 2 samples (1st is cumulative since boot, 2nd is delta)
            // -stats command,power: only need command name and energy impact
            // -o power: sort by power descending
            // -n 10: top 10 (we'll filter internally)
            task.arguments = ["-l", "2", "-stats", "pid,command,power", "-o", "power", "-n", "10"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    self.parseTopOutput(output)
                }
            } catch {
                print("Error running top: \(error)")
            }
        }
    }
    
    private var downsampledIconCache: [String: NSImage] = [:]
    
    private func downsampleIcon(for app: NSRunningApplication) -> NSImage? {
        guard let bundleId = app.bundleIdentifier else {
            return nil
        }
        
        if let cached = downsampledIconCache[bundleId] {
            return cached
        }
        
        guard let icon = app.icon else { return nil }
        
        let targetSize = NSSize(width: 32, height: 32)
        let newImage = NSImage(size: targetSize)
        
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        icon.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: icon.size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        
        downsampledIconCache[bundleId] = newImage
        return newImage
    }
    
    private func parseTopOutput(_ output: String) {
        // We only care about the second sample
        let parts = output.components(separatedBy: "Processes:")
        guard parts.count >= 3 else { return }
        
        let secondSample = parts[2]
        let lines = secondSample.components(separatedBy: .newlines)
        
        var results: [AppEnergyImpact] = []
        var foundHeader = false
        
        // Typical line: "COMMAND          POWER" followed by contents
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            if trimmed.contains("COMMAND") && trimmed.contains("POWER") {
                foundHeader = true
                continue
            }
            
            if foundHeader {
                let columns = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if columns.count >= 3 {
                    // Command often has spaces or is truncated, but power is usually the last column
                    let pidStr = columns.first ?? "0"
                    let powerStr = columns.last ?? "0"
                    let name = columns.dropFirst().dropLast().joined(separator: " ")
                    
                    if let powerValue = Double(powerStr), powerValue > 1.0, let pidValue = Int32(pidStr) {
                        // Filter out system processes that are often high but expected
                        if !isSystemProcess(name) {
                            if let app = NSRunningApplication(processIdentifier: pidValue) {
                                let icon = self.downsampleIcon(for: app)
                                results.append(AppEnergyImpact(pid: pidValue, name: name, power: powerValue, icon: icon))
                            }
                        }
                    }
                }
            }
            
            if results.count >= 3 { break }
        }
        
        DispatchQueue.main.async {
            self.highPowerApps = results
        }
    }
    
    private func isSystemProcess(_ name: String) -> Bool {
        let systemProcesses = ["WindowServer", "kernel_task", "launchd", "MacStatus"]
        return systemProcesses.contains { name.contains($0) }
    }
}
