import Foundation

let path = "MacStatus/UI/Modules/PowerFlow/SankeyPowerFlowView.swift"
var content = try String(contentsOfFile: path, encoding: .utf8)

let find = """
            HStack(spacing: -12) {
                
                if powerFlow.topology == .topologyA {
"""

let repl = """
            HStack(spacing: -12) {
                // We handle topology completely differently now to use universal Column mapping
"""

// Wait, doing this via script is risky for line overlaps. I'll use regex or multi_replace.
