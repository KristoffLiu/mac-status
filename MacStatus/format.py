import re

path = "MacStatus/UI/Modules/PowerFlow/SankeyPowerFlowView.swift"
with open(path, "r") as f:
    lines = f.readlines()

start_index = -1
end_index = -1

# Finding the exact block inside SankeyPowerFlowView
# Let's search for "VStack(spacing: 12) {" that is immediately after "CGFloat(elementsCount - 1) * 12.0) : 0.0"
for i in range(len(lines)):
    if "CGFloat(elementsCount - 1) * 12.0) : 0.0" in lines[i]:
        start_index = i + 2 # VStack(spacing: 12) {
    if "        .padding(.vertical, 8)" in lines[i] and start_index != -1 and end_index == -1:
        # Check if the previous line is `        }`
        if "}" in lines[i-1]:
            end_index = i - 1

if start_index != -1 and end_index != -1:
    print(f"Found bounds: {start_index} to {end_index}")
else:
    print("Could not find bounds")

replacement = """        HStack(alignment: .center, spacing: -12) {
            
            if powerFlow.topology == .topologyA {
                // Topology A: Adapter provides all power
                let totalSource = max(powerFlow.adapterPower, 0.1)
                let sysFlowWatts = powerFlow.systemPower
                let batChargeWatts = max(powerFlow.batteryPower, 0.0)
                let effectiveTotalForFractions = max(sysFlowWatts + batChargeWatts, 0.1)
                let sysFraction = sysFlowWatts / effectiveTotalForFractions
                let batFraction = batChargeWatts / effectiveTotalForFractions
                
                let topHeight = 35.0 + 35.0 * sysFraction
                let botHeight = max(64.0, 35.0 + 35.0 * batFraction)
                let H_total = topHeight + (batChargeWatts > 0.1 ? 12.0 + botHeight : 0)
                
                let topThick = max(12.0, CGFloat(sysFraction) * 40.0)
                let botThick = max(12.0, CGFloat(batFraction) * 40.0)
                let trunkMidTop = H_total / 2.0 - (topThick + botThick) / 2.0
                
                // LEFT PILL (Adapter)
                NodePill(icon: "powerplug.fill", value: nil, iconColor: .yellow.opacity(0.8), stretchHeight: true)
                    .frame(height: H_total)
                    .zIndex(1)
                
                // MIDDLE PIPES
                ZStack {
                    // System Path
                    ThickFlowBlock(
                        watts: sysFlowWatts,
                        fraction: min(sysFraction, 1.0),
                        startColor: .yellow.opacity(0.8),
                        endColor: .gray.opacity(0.2),
                        isSubFlow: false,
                        parentHeight: H_total,
                        explicitLeftYRange: [0, H_total * (sysFlowWatts / (sysFlowWatts + batChargeWatts))],
                        explicitRightYRange: [0, topHeight],
                        explicitMiddleYRange: [trunkMidTop, trunkMidTop + topThick]
                    )
                    
                    // Battery Path
                    if batChargeWatts > 0.1 {
                        ThickFlowBlock(
                            watts: powerFlow.batteryPower,
                            fraction: min(batFraction, 1.0),
                            startColor: .yellow.opacity(0.8),
                            endColor: .green,
                            isSubFlow: true,
                            parentHeight: H_total,
                            explicitLeftYRange: [H_total * (sysFlowWatts / (sysFlowWatts + batChargeWatts)), H_total],
                            explicitRightYRange: [topHeight + 12.0, topHeight + 12.0 + botHeight],
                            explicitMiddleYRange: [trunkMidTop + topThick, trunkMidTop + topThick + botThick]
                        )
                    }
                }
                .frame(height: H_total)
                .zIndex(0)
                
                // RIGHT PILLS
                VStack(spacing: 12) {
                    NodePill(icon: "laptopcomputer", value: showValues ? "\\(Int(sysFlowWatts))W" : nil, iconColor: .primary, stretchHeight: true)
                        .frame(height: topHeight)
                    
                    if batChargeWatts > 0.1 {
                        NodePill(icon: "battery.100.bolt", value: showValues ? "\\(Int(batChargeWatts))W" : nil, iconColor: .green, isSubNode: false, stretchHeight: true)
                            .frame(height: botHeight)
                    }
                }
                .zIndex(1)
                
                if isThreeStage {
                    ThreeStageSinksView(powerFlow: powerFlow)
                        .zIndex(0)
                }
                
            } else {
                // Topology B: System is the sink
                let isThreeStage = self.powerFlow.topology == .topologyA // Will never run here, but just for scope
                
                if powerFlow.adapterPower > 0 {
                    // Adapter is MAIN source, Battery is Sub source
                    let totalSource = max(powerFlow.adapterPower + powerFlow.batteryPower, 0.1)
                    let adFraction = powerFlow.adapterPower / totalSource
                    let batFraction = powerFlow.batteryPower / totalSource
                    
                    let topHeight = max(64.0, 35.0 + 35.0 * adFraction)
                    let botHeight = max(64.0, 35.0 + 35.0 * batFraction)
                    
                    let H_total_left = topHeight + (powerFlow.batteryPower > 0.1 ? 12.0 + botHeight : 0)
                    let actualRightH = 70.0
                    let global_H = max(H_total_left, actualRightH)
                    
                    let leftOffsetY = (global_H - H_total_left) / 2.0
                    let rightOffsetY = (global_H - actualRightH) / 2.0
                    
                    let topThick = max(12.0, CGFloat(adFraction) * 40.0)
                    let botThick = max(12.0, CGFloat(batFraction) * 40.0)
                    let trunkMidTop = global_H / 2.0 - (topThick + botThick) / 2.0
                    
                    // LEFT PILLS
                    VStack(spacing: 12) {
                        NodePill(icon: "powerplug.fill", value: nil, iconColor: .yellow.opacity(0.8), stretchHeight: true)
                            .frame(height: topHeight)
                        
                        if powerFlow.batteryPower > 0.1 {
                            NodePill(icon: "battery.100", value: nil, iconColor: .blue, isSubNode: false, stretchHeight: true)
                                .frame(height: botHeight)
                        }
                    }
                    .padding(.vertical, leftOffsetY)
                    .zIndex(1)
                    
                    // MIDDLE PIPES
                    ZStack {
                        ThickFlowBlock(
                            watts: powerFlow.adapterPower,
                            fraction: min(adFraction, 1.0),
                            startColor: .yellow.opacity(0.8),
                            endColor: .gray.opacity(0.2),
                            isSubFlow: false,
                            parentHeight: global_H,
                            explicitLeftYRange: [leftOffsetY, leftOffsetY + topHeight],
                            explicitRightYRange: [rightOffsetY, rightOffsetY + actualRightH * adFraction],
                            explicitMiddleYRange: [trunkMidTop, trunkMidTop + topThick]
                        )
                        
                        if powerFlow.batteryPower > 0.1 {
                            ThickFlowBlock(
                                watts: powerFlow.batteryPower,
                                fraction: min(batFraction, 1.0),
                                startColor: .blue,
                                endColor: .gray.opacity(0.2),
                                isSubFlow: true,
                                parentHeight: global_H,
                                explicitLeftYRange: [leftOffsetY + topHeight + 12.0, leftOffsetY + topHeight + 12.0 + botHeight],
                                explicitRightYRange: [rightOffsetY + actualRightH * adFraction, rightOffsetY + actualRightH],
                                explicitMiddleYRange: [trunkMidTop + topThick, trunkMidTop + topThick + botThick]
                            )
                        }
                    }
                    .frame(height: global_H)
                    .zIndex(0)
                    
                    // RIGHT PILL
                    NodePill(icon: "laptopcomputer", value: showValues ? "\\(Int(powerFlow.systemPower))W" : nil, iconColor: .primary, stretchHeight: true)
                        .frame(height: actualRightH)
                        .padding(.vertical, rightOffsetY)
                        .zIndex(1)
                        
                } else {
                    // Battery is MAIN and ONLY source
                    HStack(spacing: -12) {
                        NodePill(icon: "battery.100", value: nil, iconColor: .blue)
                            .zIndex(1)
                        ThickFlowBlock(
                            watts: powerFlow.batteryPower,
                            fraction: 1.0,
                            startColor: .blue,
                            endColor: .gray.opacity(0.2),
                            isSubFlow: false
                        ).zIndex(0)
                        NodePill(icon: "laptopcomputer", value: showValues ? "\\(Int(powerFlow.systemPower))W" : nil, iconColor: .primary, stretchHeight: true)
                            .zIndex(1)
                    }.frame(height: 70)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
"""

if start_index != -1 and end_index != -1:
    new_lines = lines[:start_index] + [replacement + "\n"] + lines[end_index+1:]
    with open(path, "w") as f:
        f.writelines(new_lines)
