import Foundation

let path = "MacStatus/UI/Modules/PowerFlow/SankeyPowerFlowView.swift"
var content = try String(contentsOfFile: path, encoding: .utf8)

// Fix Topology A
content = content.replacingOccurrences(of: """
                        // System Path
                        let topHeight = 35.0 + 35.0 * sysFraction
                        let botHeight = 35.0 + 35.0 * batFraction
""", with: """
                        // System Path
                        let topHeight = max(64.0, 35.0 + 35.0 * sysFraction)
                        let botHeight = max(64.0, 35.0 + 35.0 * batFraction)
""")

content = content.replacingOccurrences(of: """
                        if batChargeWatts > 0.1 {
                            let botHeight = 35.0 + 35.0 * batFraction
""", with: """
                        if batChargeWatts > 0.1 {
                            let botHeight = max(64.0, 35.0 + 35.0 * batFraction)
""")

// Fix Topology B
content = content.replacingOccurrences(of: """
                            let topHeight = 35.0 + 35.0 * adFraction
                            let botHeight = 35.0 + 35.0 * batFraction
""", with: """
                            let topHeight = max(64.0, 35.0 + 35.0 * adFraction)
                            let botHeight = max(64.0, 35.0 + 35.0 * batFraction)
""")

// Fix right logic sys ratio strictly
let findRightRatioA = "explicitLeftYRange: [0, H_total * sysFraction]"
let replRightRatioA = "explicitLeftYRange: [0, H_total * (sysFlowWatts / (sysFlowWatts + batChargeWatts))]"
content = content.replacingOccurrences(of: findRightRatioA, with: replRightRatioA)

let findBotRatioA = "explicitLeftYRange: [H_total * sysFraction - (actualTopH + 12.0), botHeight]"
let replBotRatioA = "explicitLeftYRange: [H_total * (sysFlowWatts / (sysFlowWatts + batChargeWatts)) - (actualTopH + 12.0), botHeight]"
content = content.replacingOccurrences(of: findBotRatioA, with: replBotRatioA)


// Fix sinks
let findSinks = """
        let sinksHeight = elementsCount > 0 ? ((appW > 0.1 ? 35.0 + 35.0 * (appW/totalSinks) : 0) + 
                       (coreW > 0.1 ? 35.0 + 35.0 * (coreW/totalSinks) : 0) + 
                       (periW > 0.1 ? 35.0 + 35.0 * (periW/totalSinks) : 0) +
                       CGFloat(elementsCount - 1) * 12.0) : 0.0
"""
let replSinks = """
        let sinksHeight = elementsCount > 0 ? ((appW > 0.1 ? max(46.0, 35.0 + 35.0 * (appW/totalSinks)) : 0) + 
                       (coreW > 0.1 ? max(46.0, 35.0 + 35.0 * (coreW/totalSinks)) : 0) + 
                       (periW > 0.1 ? max(46.0, 35.0 + 35.0 * (periW/totalSinks)) : 0) +
                       CGFloat(elementsCount - 1) * 12.0) : 0.0
"""
content = content.replacingOccurrences(of: findSinks, with: replSinks)

try content.write(toFile: path, atomically: true, encoding: .utf8)
