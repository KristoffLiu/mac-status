import Foundation

let path = "MacStatus/UI/Modules/PowerFlow/SankeyPowerFlowView.swift"
var content = try String(contentsOfFile: path, encoding: .utf8)

let find = """
    var body: some View {
        VStack(spacing: 12) {
"""

let repl = """
    var body: some View {
        let appW = powerFlow.topAppWatts ?? 0
        let coreW = powerFlow.coreWatts ?? 0
        let periW = powerFlow.peripheralWatts ?? 0
        let totalSinks = max(appW + coreW + periW, 0.1)
        let elementsCount = (appW > 0.1 ? 1 : 0) + (coreW > 0.1 ? 1 : 0) + (periW > 0.1 ? 1 : 0)
        let sinksHeight = elementsCount > 0 ? ((appW > 0.1 ? 35.0 + 35.0 * (appW/totalSinks) : 0) + 
                       (coreW > 0.1 ? 35.0 + 35.0 * (coreW/totalSinks) : 0) + 
                       (periW > 0.1 ? 35.0 + 35.0 * (periW/totalSinks) : 0) +
                       CGFloat(elementsCount - 1) * 12.0) : 0.0

        VStack(spacing: 12) {
"""

content = content.replacingOccurrences(of: find, with: repl)
try content.write(toFile: path, atomically: true, encoding: .utf8)
