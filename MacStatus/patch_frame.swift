import Foundation

let path = "MacStatus/UI/Modules/PowerFlow/SankeyPowerFlowView.swift"
var content = try String(contentsOfFile: path, encoding: .utf8)

// Topology A Top Pipe
content = content.replacingOccurrences(of: """
                            }
                            .frame(minHeight: topHeight)
""", with: """
                            }
""")
content = content.replacingOccurrences(of: """
                            NodePill(icon: "laptopcomputer", value: showValues ? "\\(Int(sysFlowWatts))W" : nil, iconColor: .primary, stretchHeight: true)
                                .zIndex(1)
""", with: """
                            NodePill(icon: "laptopcomputer", value: showValues ? "\\(Int(sysFlowWatts))W" : nil, iconColor: .primary, stretchHeight: true)
                                .frame(height: topHeight)
                                .zIndex(1)
""")

// Topology A Bot Pipe
content = content.replacingOccurrences(of: """
                            }
                            .frame(height: botHeight)
""", with: """
                            }
""")
content = content.replacingOccurrences(of: """
                                NodePill(icon: "battery.100.bolt", value: showValues ? "\\(Int(batChargeWatts))W" : nil, iconColor: .green, isSubNode: false, stretchHeight: true)
                                    .zIndex(1)
""", with: """
                                NodePill(icon: "battery.100.bolt", value: showValues ? "\\(Int(batChargeWatts))W" : nil, iconColor: .green, isSubNode: false, stretchHeight: true)
                                    .frame(height: botHeight)
                                    .zIndex(1)
""")

// Topology B Top Pipe
content = content.replacingOccurrences(of: """
                            }.frame(height: topHeight)
""", with: """
                            }
""")
content = content.replacingOccurrences(of: """
                                NodePill(icon: "powerplug.fill", value: nil, iconColor: .yellow.opacity(0.8), stretchHeight: true)
                                    .zIndex(1)
""", with: """
                                NodePill(icon: "powerplug.fill", value: nil, iconColor: .yellow.opacity(0.8), stretchHeight: true)
                                    .frame(height: topHeight)
                                    .zIndex(1)
""")

// Topology B Bot Pipe
content = content.replacingOccurrences(of: """
                            }.frame(height: botHeight)
""", with: """
                            }
""")
content = content.replacingOccurrences(of: """
                                NodePill(icon: "battery.100", value: nil, iconColor: .blue, isSubNode: false, stretchHeight: true)
                                    .zIndex(1)
""", with: """
                                NodePill(icon: "battery.100", value: nil, iconColor: .blue, isSubNode: false, stretchHeight: true)
                                    .frame(height: botHeight)
                                    .zIndex(1)
""")

try content.write(toFile: path, atomically: true, encoding: .utf8)
