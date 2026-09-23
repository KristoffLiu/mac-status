// Regenerate with: swift scripts/generate-app-icon.swift
// Native vector drawing, following the app's battery and power visual language.
import AppKit
import Foundation

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let destination = root.appendingPathComponent("MacStatus/MacStatus/Assets.xcassets/AppIcon.appiconset")
var images: [[String: String]] = []

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0,
                                      bitsPerPixel: 0)!
        let graphics = NSGraphicsContext(bitmapImageRep: bitmap)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        let context = graphics.cgContext
        context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)

        let tile = NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896),
                                xRadius: 200, yRadius: 200)
        NSGradient(starting: NSColor(srgbRed: 0.08, green: 0.20, blue: 0.29, alpha: 1),
                   ending: NSColor(srgbRed: 0.025, green: 0.06, blue: 0.13, alpha: 1))!
            .draw(in: tile, angle: -90)

        NSColor(srgbRed: 0.75, green: 0.94, blue: 0.91, alpha: 1).setStroke()
        let shell = NSBezierPath(roundedRect: NSRect(x: 204, y: 342, width: 574, height: 340),
                                 xRadius: 66, yRadius: 66)
        shell.lineWidth = 30
        shell.stroke()
        NSColor(srgbRed: 0.75, green: 0.94, blue: 0.91, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 805, y: 442, width: 38, height: 140),
                     xRadius: 15, yRadius: 15).fill()
        let fill = NSBezierPath(roundedRect: NSRect(x: 239, y: 377, width: 504, height: 270),
                                xRadius: 36, yRadius: 36)
        NSGradient(starting: NSColor(srgbRed: 0.13, green: 0.76, blue: 0.61, alpha: 1),
                   ending: NSColor(srgbRed: 0.61, green: 0.96, blue: 0.62, alpha: 1))!
            .draw(in: fill, angle: 20)

        let bolt = NSBezierPath()
        bolt.move(to: NSPoint(x: 548, y: 735))
        for point in [NSPoint(x: 365, y: 490), NSPoint(x: 474, y: 490),
                      NSPoint(x: 439, y: 289), NSPoint(x: 632, y: 548),
                      NSPoint(x: 523, y: 548)] { bolt.line(to: point) }
        bolt.close()
        NSColor(srgbRed: 0.035, green: 0.105, blue: 0.17, alpha: 1).setStroke()
        bolt.lineWidth = 23
        bolt.lineJoinStyle = .round
        bolt.stroke()
        NSColor.white.setFill()
        bolt.fill()

        NSGraphicsContext.restoreGraphicsState()
        let name = "icon_\(points)x\(points)@\(scale)x.png"
        try bitmap.representation(using: .png, properties: [:])!
            .write(to: destination.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(points)x\(points)",
                       "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: destination.appendingPathComponent("Contents.json"))
print("Generated 10 app icon assets in \(destination.path)")
