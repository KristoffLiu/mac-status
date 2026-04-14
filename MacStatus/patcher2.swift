import Foundation

let path = "MacStatus/UI/Modules/PowerFlow/SankeyPowerFlowView.swift"
var content = try String(contentsOfFile: path, encoding: .utf8)

// 1. In Topology A:
let find_topA = """
                        // System Path
                        let topHeight = 35.0 + 35.0 * sysFraction
                        HStack(alignment: .top, spacing: -12) {
                            ThickFlowBlock(
                                watts: sysFlowWatts,
                                fraction: min(sysFraction, 1.0),
                                startColor: .yellow.opacity(0.8),
                                endColor: .gray.opacity(0.2),
                                isSubFlow: false,
                                mergeMode: (powerFlow.batteryPower > 0.1) ? .topMerge : .none,
                                localConvergenceY: (powerFlow.batteryPower > 0.1) ? globalConvergence : nil,
                                parentHeight: topHeight
                            )
                            .zIndex(0)
"""

// Notice: we need actualTopH and H_total and sinksHeight!
// Wait! sinksHeight computation can be added before "if powerFlow.topology == .topologyA"!

let find_block = """
        let isThreeStage = powerFlowThreeStage
        
        GeometryReader { geometry in
"""
let repl_block = """
        let isThreeStage = powerFlowThreeStage
        
        let appW = powerFlow.topAppWatts ?? 0
        let coreW = powerFlow.coreWatts ?? 0
        let periW = powerFlow.peripheralWatts ?? 0
        let totalSinks = max(appW + coreW + periW, 0.1)
        let elementsCount = (appW > 0.1 ? 1 : 0) + (coreW > 0.1 ? 1 : 0) + (periW > 0.1 ? 1 : 0)
        let sinksHeight = elementsCount > 0 ? ((appW > 0.1 ? 35.0 + 35.0 * (appW/totalSinks) : 0) + 
                       (coreW > 0.1 ? 35.0 + 35.0 * (coreW/totalSinks) : 0) + 
                       (periW > 0.1 ? 35.0 + 35.0 * (periW/totalSinks) : 0) +
                       CGFloat(elementsCount - 1) * 12.0) : 0.0
        
        GeometryReader { geometry in
"""
content = content.replacingOccurrences(of: find_block, with: repl_block)

// Now replace Topology A pipes
let find_topA2 = """
                        // System Path
                        let topHeight = 35.0 + 35.0 * sysFraction
                        HStack(alignment: .top, spacing: -12) {
                            ThickFlowBlock(
                                watts: sysFlowWatts,
                                fraction: min(sysFraction, 1.0),
                                startColor: .yellow.opacity(0.8),
                                endColor: .gray.opacity(0.2),
                                isSubFlow: false,
                                mergeMode: (powerFlow.batteryPower > 0.1) ? .topMerge : .none,
                                localConvergenceY: (powerFlow.batteryPower > 0.1) ? globalConvergence : nil,
                                parentHeight: topHeight
                            )
                            .zIndex(0)
"""
let repl_topA2 = """
                        // System Path
                        let topHeight = 35.0 + 35.0 * sysFraction
                        let botHeight = 35.0 + 35.0 * batFraction
                        let actualTopH = isThreeStage ? max(topHeight, sinksHeight) : topHeight
                        let H_total = actualTopH + (powerFlow.batteryPower > 0.1 ? 12.0 + botHeight : 0)
                        
                        HStack(alignment: .top, spacing: -12) {
                            ThickFlowBlock(
                                watts: sysFlowWatts,
                                fraction: min(sysFraction, 1.0),
                                startColor: .yellow.opacity(0.8),
                                endColor: .gray.opacity(0.2),
                                isSubFlow: false,
                                parentHeight: actualTopH,
                                explicitLeftYRange: [0, H_total * sysFraction]
                            )
                            .zIndex(0)
"""
content = content.replacingOccurrences(of: find_topA2, with: repl_topA2)

let find_botA2 = """
                        if batChargeWatts > 0.1 {
                            let botHeight = 35.0 + 35.0 * batFraction
                            HStack(alignment: .bottom, spacing: -12) {
                                let topThick = max(12.0, CGFloat(sysFraction) * 40.0)
                                let botThick = max(12.0, CGFloat(batFraction) * 40.0)
                                let globalConvergence = topHeight + 6.0
                                
                                ThickFlowBlock(
                                    watts: powerFlow.batteryPower,
                                    fraction: min(batFraction, 1.0),
                                    startColor: .yellow.opacity(0.8),
                                    endColor: .green,
                                    isSubFlow: true,
                                    mergeMode: .bottomMerge,
                                    localConvergenceY: globalConvergence - (topHeight + 12.0),
                                    parentHeight: botHeight
                                )
"""
let repl_botA2 = """
                        if batChargeWatts > 0.1 {
                            let botHeight = 35.0 + 35.0 * batFraction
                            let actualTopH = isThreeStage ? max(topHeight, sinksHeight) : topHeight
                            let H_total = actualTopH + (powerFlow.batteryPower > 0.1 ? 12.0 + botHeight : 0)
                            
                            HStack(alignment: .bottom, spacing: -12) {
                                ThickFlowBlock(
                                    watts: powerFlow.batteryPower,
                                    fraction: min(batFraction, 1.0),
                                    startColor: .yellow.opacity(0.8),
                                    endColor: .green,
                                    isSubFlow: true,
                                    parentHeight: botHeight,
                                    explicitLeftYRange: [H_total * sysFraction - (actualTopH + 12.0), botHeight]
                                )
"""
content = content.replacingOccurrences(of: find_botA2, with: repl_botA2)


// Topology B:
let find_topB = """
                            let topHeight = 35.0 + 35.0 * adFraction
                            let botHeight = 35.0 + 35.0 * batFraction
                            let globalConvergence = topHeight + 6.0
                            
                            HStack(alignment: .top, spacing: -12) {
                                NodePill(icon: "powerplug.fill", value: nil, iconColor: .yellow.opacity(0.8), stretchHeight: true)
                                    .zIndex(1)
                                ThickFlowBlock(
                                    watts: powerFlow.adapterPower,
                                    fraction: min(adFraction, 1.0),
                                    startColor: .yellow.opacity(0.8),
                                    endColor: .gray.opacity(0.2),
                                    isSubFlow: false,
                                    mergeMode: .rightTopMerge,
                                    localConvergenceY: globalConvergence,
                                    parentHeight: topHeight
                                ).zIndex(0)
"""
let repl_topB = """
                            let topHeight = 35.0 + 35.0 * adFraction
                            let botHeight = 35.0 + 35.0 * batFraction
                            
                            let H_total_left = topHeight + (powerFlow.batteryPower > 0.1 ? 12.0 + botHeight : 0)
                            let actualRightH = isThreeStage ? max(70.0, sinksHeight) : 70.0
                            let global_H = max(H_total_left, actualRightH)
                            
                            let leftOffsetY = (global_H - H_total_left) / 2.0
                            let rightOffsetY = (global_H - actualRightH) / 2.0
                            
                            HStack(alignment: .top, spacing: -12) {
                                NodePill(icon: "powerplug.fill", value: nil, iconColor: .yellow.opacity(0.8), stretchHeight: true)
                                    .zIndex(1)
                                ThickFlowBlock(
                                    watts: powerFlow.adapterPower,
                                    fraction: min(adFraction, 1.0),
                                    startColor: .yellow.opacity(0.8),
                                    endColor: .gray.opacity(0.2),
                                    isSubFlow: false,
                                    parentHeight: topHeight,
                                    explicitRightYRange: [rightOffsetY - leftOffsetY, rightOffsetY + actualRightH * adFraction - leftOffsetY]
                                ).zIndex(0)
"""
content = content.replacingOccurrences(of: find_topB, with: repl_topB)

let find_botB = """
                            HStack(alignment: .bottom, spacing: -12) {
                                NodePill(icon: "battery.100", value: nil, iconColor: .blue, isSubNode: false, stretchHeight: true)
                                    .zIndex(1)
                                ThickFlowBlock(
                                    watts: powerFlow.batteryPower,
                                    fraction: min(batFraction, 1.0),
                                    startColor: .blue,
                                    endColor: .gray.opacity(0.2),
                                    isSubFlow: true,
                                    mergeMode: .rightBottomMerge,
                                    localConvergenceY: globalConvergence - (topHeight + 12.0),
                                    parentHeight: botHeight
                                ).zIndex(0)
"""
let repl_botB = """
                            HStack(alignment: .bottom, spacing: -12) {
                                NodePill(icon: "battery.100", value: nil, iconColor: .blue, isSubNode: false, stretchHeight: true)
                                    .zIndex(1)
                                ThickFlowBlock(
                                    watts: powerFlow.batteryPower,
                                    fraction: min(batFraction, 1.0),
                                    startColor: .blue,
                                    endColor: .gray.opacity(0.2),
                                    isSubFlow: true,
                                    parentHeight: botHeight,
                                    explicitRightYRange: [rightOffsetY + actualRightH * adFraction - (leftOffsetY + topHeight + 12.0), rightOffsetY + actualRightH - (leftOffsetY + topHeight + 12.0)]
                                ).zIndex(0)
"""
content = content.replacingOccurrences(of: find_botB, with: repl_botB)

try content.write(toFile: path, atomically: true, encoding: .utf8)
