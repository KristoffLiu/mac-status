import SwiftUI

/// 电池小人 — a battery body with stick-figure limbs,
/// drawn in a simple line-art (简笔画) style.
struct BatteryManView: View {
    var capacity: Int
    var isCharging: Bool

    @AppStorage("iconLowPowerColor") private var iconLowPowerColor = false

    // Configurable styles
    var isColored: Bool = false
    var showBolt: Bool = true
    var legLength: BatteryManLegLength = .normal
    var showFace: Bool = false
    var showArms: Bool = false
    var showPosture: Bool = false
    var showAccessory: Bool = false

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
    private var sideExtra: CGFloat { showArms ? armLength + 2 : 0 }

    /// Total battery+terminal width.
    private var batteryTotalW: CGFloat { bodyWidth + terminalGap + terminalWidth }

    var body: some View {
        let percentage = Double(capacity) / 100.0
        let isCritical = capacity <= 20
        let showLowPowerColor = isCritical && iconLowPowerColor

        let fillColor: Color = isCharging
            ? (isColored ? .green : .primary)
            : (showLowPowerColor ? .red : .primary)

        let strokeColor: Color = .primary

        Canvas { ctx, size in
            // ── Origins ──
            let bodyOriginX = (size.width - batteryTotalW) / 2
            let bodyOriginY = inset

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
                drawArm(ctx: ctx,
                        shoulder: CGPoint(x: bodyOriginX, y: armY),
                        direction: -1,
                        isRaised: isCharging,
                        color: strokeColor)
                drawArm(ctx: ctx,
                        shoulder: CGPoint(x: bodyOriginX + bodyWidth, y: armY),
                        direction: 1,
                        isRaised: isCharging,
                        color: strokeColor)
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
        .frame(width: batteryTotalW + sideExtra * 2 + 4,
               height: inset + bodyHeight + legHeight + footHeight + 1)
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
                         direction: CGFloat, isRaised: Bool, color: Color) {
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

        let handR: CGFloat = 1.0
        let handRect = CGRect(x: handX - handR, y: handY - handR,
                              width: handR * 2, height: handR * 2)
        ctx.fill(Path(ellipseIn: handRect), with: .color(color))
    }

    // ── Face ──
    // Two-pass approach so face is visible at any battery level:
    // 1) .clear punch knocks out fill behind each feature (needed when fill covers the face)
    // 2) Normal .primary draw on top (visible whether fill was present or not)
    private func drawFace(ctx: GraphicsContext, bodyOrigin: CGPoint,
                          capacity: Int, isCharging: Bool, strokeColor: Color) {
        let eyeY = bodyOrigin.y + bodyHeight * 0.4
        let leftEyeX = bodyOrigin.x + bodyWidth * 0.32
        let rightEyeX = bodyOrigin.x + bodyWidth * 0.68
        let eyeR: CGFloat = 1.1
        let haloR: CGFloat = eyeR + 0.8  // slightly larger for the knockout halo

        let leftEye = CGRect(x: leftEyeX - eyeR, y: eyeY - eyeR,
                             width: eyeR * 2, height: eyeR * 2)
        let rightEye = CGRect(x: rightEyeX - eyeR, y: eyeY - eyeR,
                              width: eyeR * 2, height: eyeR * 2)
        let leftHalo = CGRect(x: leftEyeX - haloR, y: eyeY - haloR,
                              width: haloR * 2, height: haloR * 2)
        let rightHalo = CGRect(x: rightEyeX - haloR, y: eyeY - haloR,
                               width: haloR * 2, height: haloR * 2)

        // Pass 1: punch halos to ensure contrast against fill
        var clearCtx = ctx
        clearCtx.blendMode = .clear
        clearCtx.fill(Path(ellipseIn: leftHalo), with: .color(.white))
        clearCtx.fill(Path(ellipseIn: rightHalo), with: .color(.white))

        // Pass 2: draw actual eyes on top
        ctx.fill(Path(ellipseIn: leftEye), with: .color(strokeColor))
        ctx.fill(Path(ellipseIn: rightEye), with: .color(strokeColor))

        // Mouth — use a filled strip (not a stroke) as the knockout halo,
        // so there are no stroke-cap artifacts and no "sausage" look.
        let mouthStrip = makeMouthStripPath(bodyOrigin: bodyOrigin,
                                            capacity: capacity,
                                            isCharging: isCharging,
                                            thickness: 2.0)
        clearCtx.fill(mouthStrip, with: .color(.white))

        // Actual mouth line
        let mouthLine = makeMouthLinePath(bodyOrigin: bodyOrigin,
                                          capacity: capacity,
                                          isCharging: isCharging)
        ctx.stroke(mouthLine, with: .color(strokeColor), lineWidth: 0.8)
    }

    private func makeMouthStripPath(bodyOrigin: CGPoint, capacity: Int,
                                    isCharging: Bool, thickness: CGFloat) -> Path {
        let mouthY = bodyOrigin.y + bodyHeight * 0.72
        let cx = bodyOrigin.x + bodyWidth * 0.5
        let w: CGFloat = 5
        var p = Path()

        if isCharging || capacity > 60 {
            let h: CGFloat = 2.0
            p.move(to: CGPoint(x: cx - w / 2, y: mouthY))
            p.addQuadCurve(to: CGPoint(x: cx + w / 2, y: mouthY),
                           control: CGPoint(x: cx, y: mouthY + h))
            p.addLine(to: CGPoint(x: cx + w / 2, y: mouthY - thickness))
            p.addQuadCurve(to: CGPoint(x: cx - w / 2, y: mouthY - thickness),
                           control: CGPoint(x: cx, y: mouthY + h - thickness))
            p.closeSubpath()
        } else if capacity <= 20 {
            let h: CGFloat = -1.2
            p.move(to: CGPoint(x: cx - w / 2, y: mouthY + 1))
            p.addQuadCurve(to: CGPoint(x: cx + w / 2, y: mouthY + 1),
                           control: CGPoint(x: cx, y: mouthY + 1 + h))
            p.addLine(to: CGPoint(x: cx + w / 2, y: mouthY + 1 - thickness))
            p.addQuadCurve(to: CGPoint(x: cx - w / 2, y: mouthY + 1 - thickness),
                           control: CGPoint(x: cx, y: mouthY + 1 + h - thickness))
            p.closeSubpath()
        } else {
            p.move(to: CGPoint(x: cx - w / 2, y: mouthY))
            p.addLine(to: CGPoint(x: cx + w / 2, y: mouthY))
            p.addLine(to: CGPoint(x: cx + w / 2, y: mouthY - thickness))
            p.addLine(to: CGPoint(x: cx - w / 2, y: mouthY - thickness))
            p.closeSubpath()
        }
        return p
    }

    private func makeMouthLinePath(bodyOrigin: CGPoint, capacity: Int,
                                   isCharging: Bool) -> Path {
        let mouthY = bodyOrigin.y + bodyHeight * 0.72
        let cx = bodyOrigin.x + bodyWidth * 0.5
        let w: CGFloat = 5
        let halfThick: CGFloat = 1.0  // thickness / 2
        var p = Path()
        if isCharging || capacity > 60 {
            p.move(to: CGPoint(x: cx - w / 2, y: mouthY - halfThick))
            p.addQuadCurve(to: CGPoint(x: cx + w / 2, y: mouthY - halfThick),
                           control: CGPoint(x: cx, y: mouthY + 2 - halfThick))
        } else if capacity <= 20 {
            p.move(to: CGPoint(x: cx - w / 2, y: mouthY + 1 - halfThick))
            p.addQuadCurve(to: CGPoint(x: cx + w / 2, y: mouthY + 1 - halfThick),
                           control: CGPoint(x: cx, y: mouthY - 1.2))
        } else {
            p.move(to: CGPoint(x: cx - w / 2, y: mouthY - halfThick))
            p.addLine(to: CGPoint(x: cx + w / 2, y: mouthY - halfThick))
        }
        return p
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

    /// Tiny lightning-bolt path centered at `center`.
    private func makeBoltPath(center: CGPoint, scale: CGFloat) -> Path {
        var p = Path()
        let pts: [(CGFloat, CGFloat)] = [
            (-1.5, -4), (0.5, -0.5), (-0.5, -0.5),
            (1.5, 4), (-0.5, 0.5), (0.5, 0.5), (-1.5, -4)
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

// MARK: - Isolated renderer

struct IsolatedBatteryManRenderer: View {
    @ObservedObject var viewModel: StatusViewModel

    @AppStorage("batteryFillStyle") private var batteryFillStyle = "monochrome"
    @AppStorage("batteryManLegLength") private var legLength: BatteryManLegLength = .normal
    @AppStorage("batteryManShowFace") private var showFace = false
    @AppStorage("batteryManShowArms") private var showArms = false
    @AppStorage("batteryManShowPosture") private var showPosture = false
    @AppStorage("batteryManShowAccessory") private var showAccessory = false

    var body: some View {
        BatteryManView(
            capacity: viewModel.currentCapacity,
            isCharging: viewModel.isCharging,
            isColored: batteryFillStyle == "status_color",
            showBolt: true,
            legLength: legLength,
            showFace: showFace,
            showArms: showArms,
            showPosture: showPosture,
            showAccessory: showAccessory
        )
        .fixedSize()
    }
}
