import SwiftUI

/// 电池小人 — a battery body with stick-figure limbs,
/// drawn in a simple line-art (简笔画) style.
struct BatteryManView: View {
    var capacity: Int
    var isCharging: Bool
    var isPowered: Bool = false  // adapter connected (covers bypass/passthrough)

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("iconLowPowerColor") private var iconLowPowerColor = false

    // Configurable styles
    var isColored: Bool = false
    var showBolt: Bool = true
    var legLength: BatteryManLegLength = .normal
    var showFace: Bool = false
    var showArms: Bool = false
    var showPosture: Bool = false
    var showAccessory: Bool = false
    var faceStyle: BatteryManFaceStyle = .outline

    // Hand item (when charging + arms enabled)
    var handItemStyle: String = "none"   // "none", "bolt", "adapter"
    var handItemSide: String = "right"   // "left", "right"

    // --- Dimensions ---
    // Body (the battery)
    private let bodyWidth: CGFloat = 20
    private let bodyHeight: CGFloat = 10
    private let bodyCorner: CGFloat = 2.5
    private let terminalWidth: CGFloat = 1.8
    private let terminalHeight: CGFloat = 3.5
    private let terminalGap: CGFloat = 0.8
    private let strokeWidth: CGFloat = 1.0

    // Legs
    private let legStroke: CGFloat = 1.2
    private let footWidth: CGFloat = 2.5
    private let footHeight: CGFloat = 1.0
    private let legInset: CGFloat = 4.5

    // Arms
    private let armStroke: CGFloat = 1.0
    private let armLength: CGFloat = 5

    // Accessory
    private let accessoryHeight: CGFloat = 6

    private var legHeight: CGFloat {
        switch legLength {
        case .short:  return 3
        case .normal: return 5
        }
    }

    /// Inset from canvas edge so the stroke isn't clipped.
    private var inset: CGFloat { strokeWidth / 2 + 0.5 }

    /// Extra width on each side for arms.
    private var sideExtra: CGFloat { showArms ? armLength + 7 : 0 }

    /// Extra space for the Q版 (outline) face so features can spill outside the battery.
    private var faceExtraTop: CGFloat { showFace && faceStyle == .outline ? 5 : 0 }
    private var faceExtraSide: CGFloat { showFace && faceStyle == .outline ? 3 : 0 }

    /// Total battery+terminal width.
    private var batteryTotalW: CGFloat { bodyWidth + terminalGap + terminalWidth }

    var body: some View {
        let percentage = Double(capacity) / 100.0
        let isCritical = capacity <= 20
        let showLowPowerColor = isCritical && iconLowPowerColor

        let fillColor: Color = isCharging
            ? (isColored ? .green : .primary)
            : (showLowPowerColor ? .red : .primary)

        let strokeColor: Color = colorScheme == .dark ? .white : .black

        Canvas { ctx, size in
            // ── Origins ──
            let bodyOriginX = (size.width - batteryTotalW) / 2
            let bodyOriginY = inset + faceExtraTop

            // ===== Accessory (drawn above frame top, Canvas doesn't clip by default) =====
            if showAccessory {
                if isCharging {
                    drawHatBolt(ctx: ctx,
                                center: CGPoint(x: bodyOriginX + bodyWidth / 2,
                                                y: bodyOriginY - 2),
                                color: strokeColor)
                } else if isCritical {
                    drawSweatDrop(ctx: ctx,
                                  origin: CGPoint(x: bodyOriginX + bodyWidth - 2,
                                                  y: bodyOriginY - accessoryHeight),
                                  color: strokeColor)
                }
            }

            // ===== Body shell =====
            let bodyRect = CGRect(x: bodyOriginX, y: bodyOriginY,
                                  width: bodyWidth, height: bodyHeight)
            let bodyPath = RoundedRectangle(cornerRadius: bodyCorner, style: .continuous)
                .path(in: bodyRect)
            ctx.stroke(bodyPath, with: .color(strokeColor), lineWidth: strokeWidth)

            // ===== Inner fill =====
            let fillInset: CGFloat = 1.5
            let maxFillW = bodyWidth - fillInset * 2
            let fillW = maxFillW * percentage
            let fillRect = CGRect(x: bodyOriginX + fillInset,
                                  y: bodyOriginY + fillInset,
                                  width: fillW,
                                  height: bodyHeight - fillInset * 2)
            let fillPath = RoundedRectangle(cornerRadius: 1.2, style: .continuous)
                .path(in: fillRect)
            ctx.fill(fillPath, with: .color(fillColor))

            // ===== Terminal tip =====
            let tipX = bodyOriginX + bodyWidth + terminalGap
            let tipY = bodyOriginY + (bodyHeight - terminalHeight) / 2
            let tipRect = CGRect(x: tipX, y: tipY,
                                 width: terminalWidth, height: terminalHeight)
            let tipPath = Capsule(style: .continuous).path(in: tipRect)
            ctx.fill(tipPath, with: .color(strokeColor))

            // ===== Charging bolt (inside body) =====
            if isCharging && showBolt && !showFace {
                let boltCenter = CGPoint(x: bodyOriginX + bodyWidth / 2,
                                         y: bodyOriginY + bodyHeight / 2)
                let boltPath = makeBoltPath(center: boltCenter, scale: 0.55)
                ctx.fill(boltPath, with: .color(isColored ? .white : .black))
            }

            // ===== Face =====
            if showFace {
                drawFace(ctx: ctx, bodyOrigin: CGPoint(x: bodyOriginX, y: bodyOriginY),
                         capacity: capacity, isCharging: isCharging, strokeColor: strokeColor)
            }

            // ===== Arms =====
            if showArms {
                let armY = bodyOriginY + bodyHeight * 0.45
                let showHandItem = (isCharging || isPowered) && handItemStyle != "none"
                let leftHandItem = handItemSide == "left" && showHandItem ? handItemStyle : "none"
                let rightHandItem = handItemSide == "right" && showHandItem ? handItemStyle : "none"
                drawArm(ctx: ctx,
                        shoulder: CGPoint(x: bodyOriginX, y: armY),
                        direction: -1,
                        isRaised: isCharging,
                        color: strokeColor,
                        handItem: leftHandItem)
                drawArm(ctx: ctx,
                        shoulder: CGPoint(x: bodyOriginX + bodyWidth, y: armY),
                        direction: 1,
                        isRaised: isCharging,
                        color: strokeColor,
                        handItem: rightHandItem)
            }

            // ===== Legs =====
            let legTopY = bodyOriginY + bodyHeight
            let legBottomY = legTopY + legHeight
            let isTired = showPosture && isCritical && !isCharging

            let leftLegX = bodyOriginX + legInset
            let rightLegX = bodyOriginX + bodyWidth - legInset

            if isTired {
                drawBentLeg(ctx: ctx, hipTop: CGPoint(x: leftLegX, y: legTopY),
                            legH: legHeight, direction: -1, color: strokeColor)
                drawBentLeg(ctx: ctx, hipTop: CGPoint(x: rightLegX, y: legTopY),
                            legH: legHeight, direction: 1, color: strokeColor)
            } else {
                drawLeg(ctx: ctx, topCenter: CGPoint(x: leftLegX, y: legTopY),
                        bottomY: legBottomY, color: strokeColor)
                drawLeg(ctx: ctx, topCenter: CGPoint(x: rightLegX, y: legTopY),
                        bottomY: legBottomY, color: strokeColor)
            }
        }
        .frame(width: batteryTotalW + sideExtra * 2 + 4 + faceExtraSide * 2,
               height: inset + bodyHeight + legHeight + footHeight + 1 + faceExtraTop)
        .compositingGroup()
    }

    // MARK: – Drawing Helpers

    // ── Straight leg ──
    private func drawLeg(ctx: GraphicsContext, topCenter: CGPoint,
                         bottomY: CGFloat, color: Color) {
        let legRect = CGRect(x: topCenter.x - legStroke / 2,
                             y: topCenter.y,
                             width: legStroke,
                             height: bottomY - topCenter.y)
        ctx.fill(Path(legRect), with: .color(color))

        let footRect = CGRect(x: topCenter.x - footWidth / 2,
                              y: bottomY,
                              width: footWidth,
                              height: footHeight)
        let footPath = RoundedRectangle(cornerRadius: footHeight / 2, style: .continuous)
            .path(in: footRect)
        ctx.fill(footPath, with: .color(color))
    }

    // ── Bent leg (tired posture) ──
    private func drawBentLeg(ctx: GraphicsContext, hipTop: CGPoint,
                             legH: CGFloat, direction: CGFloat, color: Color) {
        let kneeX = hipTop.x + direction * 3
        let kneeY = hipTop.y + legH * 0.5
        let footX = kneeX
        let footY = hipTop.y + legH

        var path = Path()
        path.move(to: hipTop)
        path.addLine(to: CGPoint(x: kneeX, y: kneeY))
        path.addLine(to: CGPoint(x: footX, y: footY))
        ctx.stroke(path, with: .color(color), lineWidth: legStroke)

        let footRect = CGRect(x: footX - footWidth / 2,
                              y: footY,
                              width: footWidth,
                              height: footHeight)
        let footPath = RoundedRectangle(cornerRadius: footHeight / 2, style: .continuous)
            .path(in: footRect)
        ctx.fill(footPath, with: .color(color))
    }

    // ── Arm ──
    private func drawArm(ctx: GraphicsContext, shoulder: CGPoint,
                         direction: CGFloat, isRaised: Bool, color: Color,
                         handItem: String = "none") {
        let handX = shoulder.x + direction * armLength
        let handY: CGFloat
        if isRaised {
            handY = shoulder.y - armLength * 0.7
        } else {
            handY = shoulder.y + armLength * 0.5
        }

        var path = Path()
        path.move(to: shoulder)
        path.addLine(to: CGPoint(x: handX, y: handY))
        ctx.stroke(path, with: .color(color), lineWidth: armStroke)

        switch handItem {
        case "bolt":
            drawSystemSymbol(in: ctx, name: "bolt.horizontal.fill", at: CGPoint(x: handX, y: handY), size: 9, color: color, rotation: 90)
        case "adapter":
            drawSystemSymbol(in: ctx, name: "powerplug.fill", at: CGPoint(x: handX, y: handY), size: 10, color: color, rotation: -90)
        default:
            let handR: CGFloat = 1.0
            let handRect = CGRect(x: handX - handR, y: handY - handR,
                                  width: handR * 2, height: handR * 2)
            ctx.fill(Path(ellipseIn: handRect), with: .color(color))
        }
    }

    /// Draws a system symbol via NSImage -> CGImage with proper tinting and rotation.
    private func drawSystemSymbol(in ctx: GraphicsContext, name: String, at: CGPoint, size: CGFloat, color: Color, rotation: CGFloat = 0) {
        guard let nsImage = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return }

        let config = NSImage.SymbolConfiguration(pointSize: size, weight: .bold)
        let configured = nsImage.withSymbolConfiguration(config) ?? nsImage
        configured.isTemplate = true

        var rect = CGRect(origin: .zero, size: configured.size)
        guard let cgImage = configured.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return }

        ctx.withCGContext { cgCtx in
            cgCtx.saveGState()
            cgCtx.translateBy(x: at.x, y: at.y)
            cgCtx.rotate(by: CGFloat(rotation) * .pi / 180)
            let drawRect = CGRect(x: -rect.width / 2, y: -rect.height / 2, width: rect.width, height: rect.height)
            cgCtx.draw(cgImage, in: drawRect)
            cgCtx.setBlendMode(.sourceIn)
            let nsColor: NSColor = (color == .white) ? .white : (color == .black) ? .black : NSColor(color)
            cgCtx.setFillColor(nsColor.cgColor)
            cgCtx.fill(drawRect)
            cgCtx.restoreGState()
        }
    }

    // ── Face ──
    private func drawFace(ctx: GraphicsContext, bodyOrigin: CGPoint,
                          capacity: Int, isCharging: Bool, strokeColor: Color) {
        let isChibi = faceStyle == .outline
        let scale: CGFloat = isChibi ? 1.6 : 1.0

        let eyeY = bodyOrigin.y + bodyHeight * (isChibi ? 0.30 : 0.40)
        let leftEyeX = bodyOrigin.x + bodyWidth * (isChibi ? 0.25 : 0.32)
        let rightEyeX = bodyOrigin.x + bodyWidth * (isChibi ? 0.75 : 0.68)
        let eyeR: CGFloat = 1.1 * scale

        let leftEye = CGRect(x: leftEyeX - eyeR, y: eyeY - eyeR,
                             width: eyeR * 2, height: eyeR * 2)
        let rightEye = CGRect(x: rightEyeX - eyeR, y: eyeY - eyeR,
                              width: eyeR * 2, height: eyeR * 2)

        let mouthY = bodyOrigin.y + bodyHeight * (isChibi ? 0.85 : 0.72)
        let cx = bodyOrigin.x + bodyWidth * 0.5
        let w: CGFloat = 5 * scale

        var mouthPath = Path()
        if isCharging || capacity > 60 {
            mouthPath.move(to: CGPoint(x: cx - w / 2, y: mouthY - 1 * scale))
            mouthPath.addQuadCurve(to: CGPoint(x: cx + w / 2, y: mouthY - 1 * scale),
                                   control: CGPoint(x: cx, y: mouthY + 1 * scale))
        } else if capacity <= 20 {
            mouthPath.move(to: CGPoint(x: cx - w / 2, y: mouthY))
            mouthPath.addQuadCurve(to: CGPoint(x: cx + w / 2, y: mouthY),
                                   control: CGPoint(x: cx, y: mouthY - 2.2 * scale))
        } else {
            mouthPath.move(to: CGPoint(x: cx - w / 2, y: mouthY - 1 * scale))
            mouthPath.addLine(to: CGPoint(x: cx + w / 2, y: mouthY - 1 * scale))
        }

        // Shared fill path for solid clipping.
        let percentage = Double(capacity) / 100.0
        let fillInset: CGFloat = 1.5
        let maxFillW = bodyWidth - fillInset * 2
        let fillW = maxFillW * percentage
        let fillRect = CGRect(x: bodyOrigin.x + fillInset,
                              y: bodyOrigin.y + fillInset,
                              width: fillW,
                              height: bodyHeight - fillInset * 2)
        let fillPath = RoundedRectangle(cornerRadius: 1.2, style: .continuous).path(in: fillRect)

        let leftEyePath = Path(ellipseIn: leftEye)
        let rightEyePath = Path(ellipseIn: rightEye)

        switch faceStyle {
        case .solid:
            // Eyes: black on fill, white on background
            ctx.fill(leftEyePath.intersection(fillPath), with: .color(.black))
            ctx.fill(leftEyePath.subtracting(fillPath), with: .color(.white))
            ctx.fill(rightEyePath.intersection(fillPath), with: .color(.black))
            ctx.fill(rightEyePath.subtracting(fillPath), with: .color(.white))

            // Mouth as a filled "sausage" shape, clipped against the battery fill.
            let mouthSausage: Path = {
                if isCharging || capacity > 60 {
                    let p0 = CGPoint(x: cx - w / 2, y: mouthY - 1 * scale)
                    let p1 = CGPoint(x: cx, y: mouthY + 1 * scale)
                    let p2 = CGPoint(x: cx + w / 2, y: mouthY - 1 * scale)
                    return makeSausageFromQuadCurve(p0: p0, p1: p1, p2: p2, lineWidth: 1.5 * scale)
                } else if capacity <= 20 {
                    let p0 = CGPoint(x: cx - w / 2, y: mouthY)
                    let p1 = CGPoint(x: cx, y: mouthY - 2.2 * scale)
                    let p2 = CGPoint(x: cx + w / 2, y: mouthY)
                    return makeSausageFromQuadCurve(p0: p0, p1: p1, p2: p2, lineWidth: 1.5 * scale)
                } else {
                    let rect = CGRect(x: cx - w / 2, y: mouthY - 1 * scale - 0.75 * scale, width: w, height: 1.5 * scale)
                    return RoundedRectangle(cornerRadius: 0.75 * scale, style: .continuous).path(in: rect)
                }
            }()
            ctx.fill(mouthSausage.intersection(fillPath), with: .color(.black))
            ctx.fill(mouthSausage.subtracting(fillPath), with: .color(.white))

        case .outline, .hollow:
            // Solid outline + transparent fill (hollow features)
            let haloR = eyeR + 0.8 * scale
            let leftHalo = CGRect(x: leftEyeX - haloR, y: eyeY - haloR,
                                  width: haloR * 2, height: haloR * 2)
            let rightHalo = CGRect(x: rightEyeX - haloR, y: eyeY - haloR,
                                   width: haloR * 2, height: haloR * 2)

            // Eyes: solid outer ring, hollow inside
            ctx.fill(Path(ellipseIn: leftHalo), with: .color(strokeColor))
            ctx.fill(Path(ellipseIn: rightHalo), with: .color(strokeColor))

            var clearCtx = ctx
            clearCtx.blendMode = .clear
            clearCtx.fill(Path(ellipseIn: leftEye), with: .color(.white))
            clearCtx.fill(Path(ellipseIn: rightEye), with: .color(.white))

            // Mouth: solid outline tube, hollow inside
            let outerMouth = mouthPath.strokedPath(StrokeStyle(lineWidth: 3.5 * scale, lineCap: .round, lineJoin: .round))
            let innerMouth = mouthPath.strokedPath(StrokeStyle(lineWidth: 1.5 * scale, lineCap: .round, lineJoin: .round))
            ctx.fill(outerMouth, with: .color(strokeColor))
            clearCtx.fill(innerMouth, with: .color(.white))
        }
    }

    // ── Hat bolt (charging accessory) ──
    private func drawHatBolt(ctx: GraphicsContext, center: CGPoint, color: Color) {
        let boltPath = makeBoltPath(center: CGPoint(x: center.x, y: center.y - 3), scale: 0.5)
        ctx.fill(boltPath, with: .color(color))
    }

    // ── Sweat drop (low battery accessory) ──
    private func drawSweatDrop(ctx: GraphicsContext, origin: CGPoint, color: Color) {
        var path = Path()
        let tipX = origin.x
        let tipY = origin.y
        let bottomY = tipY + 4
        let w: CGFloat = 2.0

        path.move(to: CGPoint(x: tipX, y: tipY))
        path.addQuadCurve(to: CGPoint(x: tipX, y: bottomY),
                          control: CGPoint(x: tipX - w, y: tipY + 3))
        path.addQuadCurve(to: CGPoint(x: tipX, y: tipY),
                          control: CGPoint(x: tipX + w, y: tipY + 3))
        path.closeSubpath()
        ctx.fill(path, with: .color(color))
    }

    /// Turn a quadratic Bézier curve into a closed filled "sausage" path.
    private func makeSausageFromQuadCurve(p0: CGPoint, p1: CGPoint, p2: CGPoint, lineWidth: CGFloat) -> Path {
        let steps = 24
        let r = lineWidth / 2
        var upper: [CGPoint] = []
        var lower: [CGPoint] = []

        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let x = (1 - t) * (1 - t) * p0.x + 2 * (1 - t) * t * p1.x + t * t * p2.x
            let y = (1 - t) * (1 - t) * p0.y + 2 * (1 - t) * t * p1.y + t * t * p2.y

            let dx = 2 * (1 - t) * (p1.x - p0.x) + 2 * t * (p2.x - p1.x)
            let dy = 2 * (1 - t) * (p1.y - p0.y) + 2 * t * (p2.y - p1.y)
            let len = hypot(dx, dy)
            guard len > 0 else { continue }
            let nx = -dy / len * r
            let ny =  dx / len * r

            upper.append(CGPoint(x: x + nx, y: y + ny))
            lower.append(CGPoint(x: x - nx, y: y - ny))
        }

        var path = Path()
        if let first = upper.first {
            path.move(to: first)
            for pt in upper.dropFirst() { path.addLine(to: pt) }
            for pt in lower.reversed()  { path.addLine(to: pt) }
            path.closeSubpath()
        }
        return path
    }

    /// Tiny lightning-bolt path centered at `center`.
    private func makeBoltPath(center: CGPoint, scale: CGFloat, widthMultiplier: CGFloat = 1.0) -> Path {
        var p = Path()
        let pts: [(CGFloat, CGFloat)] = [
            (-1.5 * widthMultiplier, -4), (0.5 * widthMultiplier, -0.5), (-0.5 * widthMultiplier, -0.5),
            (1.5 * widthMultiplier, 4), (-0.5 * widthMultiplier, 0.5), (0.5 * widthMultiplier, 0.5), (-1.5 * widthMultiplier, -4)
        ]
        for (i, pt) in pts.enumerated() {
            let x = center.x + pt.0 * scale
            let y = center.y + pt.1 * scale
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        p.closeSubpath()
        return p
    }

    /// A proper filled lightning-bolt shape for the hand item.
}

// MARK: - Settings enums

enum BatteryManLegLength: String, CaseIterable, Identifiable {
    case short = "short"
    case normal = "normal"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .short:  return "短腿"
        case .normal: return "长腿"
        }
    }
}

enum BatteryManFaceStyle: String, CaseIterable, Identifiable {
    case solid = "solid"
    case hollow = "hollow"
    case outline = "outline"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .solid:   return "实心"
        case .hollow:  return "空心"
        case .outline: return "Q版大头"
        }
    }
}

// MARK: - Isolated renderer

struct IsolatedBatteryManRenderer: View {
    @ObservedObject var viewModel: StatusViewModel

    @AppStorage("batteryFillStyle") private var batteryFillStyle = "monochrome"
    @AppStorage("batteryManLegLength") private var legLength: BatteryManLegLength = .normal
    @AppStorage("batteryManShowFace") private var showFace = false
    @AppStorage("batteryManShowArms") private var showArms = false
    @AppStorage("batteryManShowPosture") private var showPosture = false
    @AppStorage("batteryManShowAccessory") private var showAccessory = false
    @AppStorage("batteryManFaceStyle") private var faceStyle: BatteryManFaceStyle = .outline
    @AppStorage("batteryManHandItemStyle") private var handItemStyle = "none"
    @AppStorage("batteryManHandItemSide") private var handItemSide = "right"

    var body: some View {
        BatteryManView(
            capacity: viewModel.currentCapacity,
            isCharging: viewModel.isCharging,
            isPowered: viewModel.batteryData.adapter != nil,
            isColored: batteryFillStyle == "status_color",
            showBolt: true,
            legLength: legLength,
            showFace: showFace,
            showArms: showArms,
            showPosture: showPosture,
            showAccessory: showAccessory,
            faceStyle: faceStyle,
            handItemStyle: handItemStyle,
            handItemSide: handItemSide
        )
        .fixedSize()
    }
}
