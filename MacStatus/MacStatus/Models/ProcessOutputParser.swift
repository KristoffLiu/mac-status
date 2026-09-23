import Foundation

nonisolated struct ProcessUsage: Sendable, Equatable {
    let pid: Int32
    let name: String
    let value: Double
}

nonisolated enum ProcessOutputParser {
    static func cpu(_ output: String) -> [ProcessUsage] {
        output.split(separator: "\n").compactMap { line in
            let parts = line.split(maxSplits: 2, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
            guard parts.count == 3, let pid = Int32(parts[0]), let value = Double(parts[1]), value.isFinite, value >= 0 else { return nil }
            return ProcessUsage(pid: pid, name: String(parts[2]), value: value)
        }
    }

    static func energy(_ output: String) -> [ProcessUsage]? {
        let samples = output.components(separatedBy: "Processes:")
        guard samples.count >= 3, let last = samples.last else { return nil }
        var foundHeader = false
        var result: [ProcessUsage] = []
        for line in last.split(separator: "\n") {
            if line.contains("PID") && line.contains("COMMAND") && line.contains("POWER") { foundHeader = true; continue }
            guard foundHeader else { continue }
            let parts = line.split(whereSeparator: \.isWhitespace)
            guard parts.count >= 3, let pid = Int32(parts[0]), let value = Double(parts.last!), value.isFinite, value >= 0 else { continue }
            result.append(ProcessUsage(pid: pid, name: parts.dropFirst().dropLast().joined(separator: " "), value: value))
        }
        return foundHeader ? result : nil
    }
}
