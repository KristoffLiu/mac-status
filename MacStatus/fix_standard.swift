import Foundation

let path = "MacStatus/UI/Modules/PowerFlow/SankeyPowerFlowView.swift"
var original = try String(contentsOfFile: path, encoding: .utf8)

let findStandard = """
        if sankeyStyle == "standard" {
            // Standard continuous Sankey S-curve using 2 segments to enforce unified trunk alignment
            path.addCurve(to: CGPoint(x: w * 0.5, y: midTopY),
                          control1: CGPoint(x: w * 0.25, y: leftTopY),
                          control2: CGPoint(x: w * 0.25, y: midTopY))
            
            path.addCurve(to: CGPoint(x: w, y: rightTopY),
                          control1: CGPoint(x: w * 0.75, y: midTopY),
                          control2: CGPoint(x: w * 0.75, y: rightTopY))
            
            path.addLine(to: CGPoint(x: w, y: rightBotY))
            
            path.addCurve(to: CGPoint(x: w * 0.5, y: midBotY),
                          control1: CGPoint(x: w * 0.75, y: rightBotY),
                          control2: CGPoint(x: w * 0.75, y: midBotY))
            
            path.addCurve(to: CGPoint(x: 0, y: leftBotY),
                          control1: CGPoint(x: w * 0.25, y: midBotY),
                          control2: CGPoint(x: w * 0.25, y: leftBotY))
            
            path.closeSubpath()
            return path
        }
"""

let replStandard = """
        if sankeyStyle == "standard" {
            // Standard continuous Sankey S-curve
            path.addCurve(to: CGPoint(x: w, y: rightTopY),
                          control1: CGPoint(x: w * 0.5, y: leftTopY),
                          control2: CGPoint(x: w * 0.5, y: rightTopY))
            
            path.addLine(to: CGPoint(x: w, y: rightBotY))
            
            path.addCurve(to: CGPoint(x: 0, y: leftBotY),
                          control1: CGPoint(x: w * 0.5, y: rightBotY),
                          control2: CGPoint(x: w * 0.5, y: leftBotY))
            
            path.closeSubpath()
            return path
        }
"""

let res = original.replacingOccurrences(of: findStandard, with: replStandard)
try res.write(toFile: path, atomically: true, encoding: .utf8)
