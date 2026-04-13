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
    
    private var timer: AnyCancellable?
    
    private init() {
        startPolling()
    }
    
    func startPolling() {
        // Poll every 10 seconds to avoid excessive CPU usage by 'top'
        timer = Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchTopApps()
            }
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
                            let app = NSRunningApplication(processIdentifier: pidValue)
                            let icon = app?.icon
                            results.append(AppEnergyImpact(pid: pidValue, name: name, power: powerValue, icon: icon))
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
