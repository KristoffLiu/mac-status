import Foundation

let path = "MacStatus/UI/Modules/PowerFlow/SankeyPowerFlowView.swift"
var content = try String(contentsOfFile: path, encoding: .utf8)

let findBlock = """
                        let topHeight = max(64.0, 35.0 + 35.0 * sysFraction)
                        
                        HStack(alignment: .top, spacing: -12) {
                            let topThick = max(12.0, CGFloat(sysFraction) * 40.0)
                            let botThick = max(12.0, CGFloat(batFraction) * 40.0)
                            let globalConvergence = topHeight + 6.0
                            
                            ThickFlowBlock(
"""

let replBlock = """
                        let topHeight = max(64.0, 35.0 + 35.0 * sysFraction)
                        let botHeightTemp = max(64.0, 35.0 + 35.0 * batFraction)
                        let actualTopH = isThreeStage ? max(topHeight, sinksHeight) : topHeight
                        let H_total = actualTopH + (batChargeWatts > 0.1 ? 12.0 + botHeightTemp : 0)
                        
                        HStack(alignment: .top, spacing: -12) {
                            ThickFlowBlock(
"""

content = content.replacingOccurrences(of: findBlock, with: replBlock)

try content.write(toFile: path, atomically: true, encoding: .utf8)
