import Foundation

let path = "MacStatus/UI/Modules/PowerFlow/SankeyPowerFlowView.swift"
var lines = try String(contentsOfFile: path, encoding: .utf8).components(separatedBy: .newlines)

// We will overwrite SankeyPowerFlowView to decouple pipelines.
