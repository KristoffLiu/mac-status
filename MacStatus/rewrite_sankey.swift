import Foundation

let path = "MacStatus/UI/Modules/PowerFlow/SankeyPowerFlowView.swift"
var content = try String(contentsOfFile: path, encoding: .utf8)

// 1. We replace the body to use decoupled pipelines!
// Because we have to replace an exact chunk of code, we will write a script to replace the body of SankeyPowerFlowView.
// But wait, it's safer to just provide a complete file replacement or use multi_replace.
// Let's use `multi_replace_file_content` instead of this script script.
