import Foundation

let path = "MacStatus/UI/Modules/PowerFlow/SankeyPowerFlowView.swift"
var content = try String(contentsOfFile: path)

var lines = content.components(separatedBy: .newlines)

var i = 0
while i < lines.count {
    if lines[i].contains("WatchBandShape(thickness: thickness, leftHeight: leftH, rightHeight: rightH, mergeMode: mergeMode, localConvergenceY: localConvergenceY, sankeyStyle: sankeyStyle)") {
        lines[i] = lines[i].replacingOccurrences(of: "WatchBandShape(thickness: thickness, leftHeight: leftH, rightHeight: rightH, mergeMode: mergeMode, localConvergenceY: localConvergenceY, sankeyStyle: sankeyStyle)", with: "WatchBandShape(thickness: thickness, leftHeight: leftH, rightHeight: rightH, mergeMode: mergeMode, localConvergenceY: localConvergenceY, sankeyStyle: sankeyStyle, explicitLeftYRange: explicitLeftYRange, explicitRightYRange: explicitRightYRange)")
    }
    
    if lines[i].contains("var sankeyStyle: String = \"watchband\"") && lines[i].hasPrefix("    var") {
        if !lines[i+1].contains("explicitLeftYRange") {
            lines.insert("    var explicitLeftYRange: [CGFloat]? = nil", at: i + 1)
            lines.insert("    var explicitRightYRange: [CGFloat]? = nil", at: i + 2)
            i += 2
        }
    }
    
    i += 1
}

content = lines.joined(separator: "\n")

let find_merges = """
        let mergeSpread = sankeyStyle == "standard" ? safeThick : (safeThick * 1.5 + 12.0)
        
        // Apply Left merges
        if mergeMode == .topMerge, let convergence = localConvergenceY {
            leftBotY = convergence
            leftTopY = convergence - mergeSpread 
        } else if mergeMode == .bottomMerge, let convergence = localConvergenceY {
            leftTopY = convergence
            leftBotY = convergence + mergeSpread
        }
        
        // Apply Right merges
        if mergeMode == .rightTopMerge, let convergence = localConvergenceY {
            rightBotY = convergence
            rightTopY = convergence - mergeSpread
        } else if mergeMode == .rightBottomMerge, let convergence = localConvergenceY {
            rightTopY = convergence
            rightBotY = convergence + mergeSpread
        }
"""

let repl_merges = """
        let mergeSpread = sankeyStyle == "standard" ? safeThick : (safeThick * 1.5 + 12.0)
        
        // Apply Left merges
        if let explicitLeft = explicitLeftYRange, explicitLeft.count == 2 {
            leftTopY = explicitLeft[0]
            leftBotY = explicitLeft[1]
        } else if mergeMode == .topMerge, let convergence = localConvergenceY {
            leftBotY = convergence
            leftTopY = convergence - mergeSpread 
        } else if mergeMode == .bottomMerge, let convergence = localConvergenceY {
            leftTopY = convergence
            leftBotY = convergence + mergeSpread
        }
        
        // Apply Right merges
        if let explicitRight = explicitRightYRange, explicitRight.count == 2 {
            rightTopY = explicitRight[0]
            rightBotY = explicitRight[1]
        } else if mergeMode == .rightTopMerge, let convergence = localConvergenceY {
            rightBotY = convergence
            rightTopY = convergence - mergeSpread
        } else if mergeMode == .rightBottomMerge, let convergence = localConvergenceY {
            rightTopY = convergence
            rightBotY = convergence + mergeSpread
        }
"""

content = content.replacingOccurrences(of: find_merges, with: repl_merges)

try content.write(toFile: path, atomically: true, encoding: .utf8)
