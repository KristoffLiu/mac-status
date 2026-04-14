import Foundation
let path = "MacStatus/UI/Modules/PowerFlow/SankeyPowerFlowView.swift"
var content = try String(contentsOfFile: path, encoding: .utf8)

let findA = """
                            let localHTotal = topHeight + (batChargeWatts > 0.1 ? 12.0 + max(64.0, 35.0 + 35.0 * batFraction) : 0)
                            ThickFlowBlock(
                                watts: sysFlowWatts,
                                fraction: min(sysFraction, 1.0),
                                startColor: .yellow.opacity(0.8),
                                endColor: .gray.opacity(0.2),
                                isSubFlow: false,
                                parentHeight: topHeight,
                                explicitLeftYRange: [0, localHTotal * (sysFlowWatts / (sysFlowWatts + batChargeWatts))]
                            )
"""

let replA = """
                            let localHTotal = topHeight + (batChargeWatts > 0.1 ? 12.0 + max(64.0, 35.0 + 35.0 * batFraction) : 0)
                            let trunkMidTop = localHTotal / 2.0 - (topThick + botThick) / 2.0
                            ThickFlowBlock(
                                watts: sysFlowWatts,
                                fraction: min(sysFraction, 1.0),
                                startColor: .yellow.opacity(0.8),
                                endColor: .gray.opacity(0.2),
                                isSubFlow: false,
                                parentHeight: topHeight,
                                explicitLeftYRange: [0, localHTotal * (sysFlowWatts / (sysFlowWatts + batChargeWatts))],
                                explicitMiddleYRange: [trunkMidTop, trunkMidTop + topThick]
                            )
"""

content = content.replacingOccurrences(of: findA, with: replA)

let findABot = """
                                    parentHeight: botHeight,
                                    explicitLeftYRange: [H_total * (sysFlowWatts / (sysFlowWatts + batChargeWatts)) - (actualTopH + 12.0), botHeight]
                                )
"""

let replABot = """
                                    parentHeight: botHeight,
                                    explicitLeftYRange: [H_total * (sysFlowWatts / (sysFlowWatts + batChargeWatts)) - (actualTopH + 12.0), botHeight],
                                    explicitMiddleYRange: [H_total / 2.0 - (topThick + max(12.0, CGFloat(batFraction) * 40.0)) / 2.0 + topThick - (actualTopH + 12.0), H_total / 2.0 + (max(12.0, CGFloat(batFraction) * 40.0) - topThick) / 2.0 - (actualTopH + 12.0)]
                                )
"""

content = content.replacingOccurrences(of: findABot, with: replABot)

try content.write(toFile: path, atomically: true, encoding: .utf8)
