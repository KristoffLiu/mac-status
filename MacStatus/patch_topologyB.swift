import Foundation
let path = "MacStatus/UI/Modules/PowerFlow/SankeyPowerFlowView.swift"
var content = try String(contentsOfFile: path, encoding: .utf8)

let findB = """
                            let leftOffsetY = (global_H - H_total_left) / 2.0
                            let rightOffsetY = (global_H - actualRightH) / 2.0
                            
                            HStack(alignment: .top, spacing: -12) {
"""

let replB = """
                            let leftOffsetY = (global_H - H_total_left) / 2.0
                            let rightOffsetY = (global_H - actualRightH) / 2.0
                            
                            let topThick = max(12.0, CGFloat(adFraction) * 40.0)
                            let botThick = max(12.0, CGFloat(batFraction) * 40.0)
                            let trunkMidTop = global_H / 2.0 - (topThick + botThick) / 2.0
                            
                            HStack(alignment: .top, spacing: -12) {
"""

content = content.replacingOccurrences(of: findB, with: replB)

let findBTop = """
                                    isSubFlow: false,
                                    parentHeight: topHeight,
                                    explicitRightYRange: [rightOffsetY - leftOffsetY, rightOffsetY + actualRightH * adFraction - leftOffsetY]
                                ).zIndex(0)
"""

let replBTop = """
                                    isSubFlow: false,
                                    parentHeight: topHeight,
                                    explicitRightYRange: [rightOffsetY - leftOffsetY, rightOffsetY + actualRightH * adFraction - leftOffsetY],
                                    explicitMiddleYRange: [trunkMidTop - leftOffsetY, trunkMidTop + topThick - leftOffsetY]
                                ).zIndex(0)
"""

content = content.replacingOccurrences(of: findBTop, with: replBTop)

let findBBot = """
                                    isSubFlow: true,
                                    parentHeight: botHeight,
                                    explicitRightYRange: [rightOffsetY + actualRightH * adFraction - (leftOffsetY + topHeight + 12.0), rightOffsetY + actualRightH - (leftOffsetY + topHeight + 12.0)]
                                ).zIndex(0)
"""

let replBBot = """
                                    isSubFlow: true,
                                    parentHeight: botHeight,
                                    explicitRightYRange: [rightOffsetY + actualRightH * adFraction - (leftOffsetY + topHeight + 12.0), rightOffsetY + actualRightH - (leftOffsetY + topHeight + 12.0)],
                                    explicitMiddleYRange: [trunkMidTop + topThick - (leftOffsetY + topHeight + 12.0), trunkMidTop + topThick + botThick - (leftOffsetY + topHeight + 12.0)]
                                ).zIndex(0)
"""

content = content.replacingOccurrences(of: findBBot, with: replBBot)

try content.write(toFile: path, atomically: true, encoding: .utf8)
