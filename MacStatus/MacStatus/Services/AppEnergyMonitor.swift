import Foundation
import Combine
import AppKit

struct TopAppUsage {
    var name: String
    var cpuPercent: Double
}

class AppEnergyMonitor: ObservableObject {
    static let shared = AppEnergyMonitor()
    
    @Published var topApp: TopAppUsage?
    private var timerCancellable: AnyCancellable?
    
    private init() {
        // Tie to EnergyEfficiencyManager tick to start/stop polling
        EnergyEfficiencyManager.shared.$appState
            .sink { [weak self] state in
                if state == .active {
                    self?.startPolling()
                } else {
                    self?.stopPolling()
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var isFetching = false
    
    private func startPolling() {
        stopPolling()
        
        let interval = UserDefaults.standard.double(forKey: "activeUpdateInterval")
        let activeInterval = interval > 0 ? interval : 1.0
        
        // Use a 2x interval to avoid spamming `ps` too aggressively while still tracking real-time
        let fetchInterval = max(2.0, activeInterval * 2)
        
        timerCancellable = Timer.publish(every: fetchInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchTopApp()
            }
        
        fetchTopApp()
    }
    
    private func stopPolling() {
        timerCancellable?.cancel()
    }
    
    private func fetchTopApp() {
        guard !isFetching else { return }
        isFetching = true
        
        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            let pipe = Pipe()
            
            task.standardOutput = pipe
            task.standardError = pipe
            task.arguments = ["-c", "ps -A -o %cpu,comm -r -m | grep -v 'kernel_task' | grep -v 'WindowServer' | grep -v 'coreaudiod' | head -n 4"]
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    
                    // Parse output
                    let lines = output.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    
                    var bestApp: TopAppUsage? = nil
                    
                    for line in lines {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        if trimmed.hasPrefix("%CPU") { continue }
                        
                        let components = trimmed.components(separatedBy: .whitespaces)
                        guard components.count >= 2 else { continue }
                        
                        if let cpuStr = components.first, let cpuRaw = Double(cpuStr) {
                            let name = components.dropFirst().joined(separator: " ")
                            
                            // Filter out completely generic/system names if possible, but we've already done grep -v
                            // Only care if CPU > 5%
                            if cpuRaw > 5.0 {
                                // Extract readable name from path if needed. Comm gives the raw command.
                                // Because we used -r, it's just the command name.
                                // We might see paths if it's an Electron app like /Applications/Antigravity...
                                var cleanName = name
                                if name.contains("/") {
                                    if let last = name.components(separatedBy: "/").last {
                                        cleanName = last
                                    }
                                }
                                
                                // Strip trailing (Renderer) etc
                                if let range = cleanName.range(of: " (") {
                                    cleanName = String(cleanName[..<range.lowerBound])
                                }
                                
                                if cleanName == "ps" || cleanName == "grep" || cleanName == "sh" {
                                    continue
                                }
                                
                                bestApp = TopAppUsage(name: cleanName, cpuPercent: cpuRaw)
                                break // We found the top user app!
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.topApp = bestApp
                        self.isFetching = false
                    }
                } else {
                    DispatchQueue.main.async { self.isFetching = false }
                }
            } catch {
                DispatchQueue.main.async { self.isFetching = false }
            }
        }
    }
}
