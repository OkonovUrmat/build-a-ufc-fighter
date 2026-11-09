import SwiftUI
import GoatDomain

/// Geometry of the fighter silhouette, authored in a 100 × 200 unit box.
/// Everything (body shape, gloves, attribute anchors) shares these coordinates,
/// so connector lines always land on the right body region at any size.
enum SilhouetteGeometry {
    static let unitWidth: CGFloat = 100
    static let unitHeight: CGFloat = 200

    /// Largest 1:2 rect centred in `rect`.
    static func fittedRect(in rect: CGRect) -> CGRect {
        let width = min(rect.width, rect.height * unitWidth / unitHeight)
        let height = width * unitHeight / unitWidth
        return CGRect(x: rect.midX - width / 2, y: rect.midY - height / 2, width: width, height: height)
    }

    static func point(_ unit: CGPoint, in fitted: CGRect) -> CGPoint {
        let scale = fitted.width / unitWidth
        return CGPoint(x: fitted.minX + unit.x * scale, y: fitted.minY + unit.y * scale)
    }

    /// Body region each attribute connects to.
    static func anchor(for attribute: FighterAttribute) -> CGPoint {
        switch attribute {
        case .fightIQ: return CGPoint(x: 50, y: 13)      // brain
        case .striking: return CGPoint(x: 31, y: 30)     // lead glove
        case .chin: return CGPoint(x: 50, y: 34)         // jaw
        case .wrestling: return CGPoint(x: 41, y: 99)    // hips
        case .kicking: return CGPoint(x: 31, y: 165)     // shin
        case .size: return CGPoint(x: 66, y: 47)         // shoulder frame
        case .power: return CGPoint(x: 80, y: 60)        // arm
        case .cardio: return CGPoint(x: 56, y: 64)       // chest
        case .groundGame: return CGPoint(x: 67, y: 148)  // knee
        case .speed: return CGPoint(x: 78, y: 190)       // foot
        }
    }
}

/// Full-body fighter in a high guard, wide stance. Pieces are unioned (iOS 17
/// `Path.union`) so strokes trace one clean outline.
struct FighterBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let frame = SilhouetteGeometry.fittedRect(in: rect)
        let s = frame.width / SilhouetteGeometry.unitWidth
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            SilhouetteGeometry.point(CGPoint(x: x, y: y), in: frame)
        }

        var pieces: [Path] = []

        // Head
        pieces.append(Path(ellipseIn: CGRect(x: frame.minX + 39.5 * s, y: frame.minY + 9 * s, width: 21 * s, height: 25 * s)))
        // Neck
        pieces.append(limb(p(50, 30), p(50, 44), width: 10 * s))
        // Torso (V-taper)
        var torso = Path()
        torso.addLines([p(29, 45), p(71, 45), p(65, 76), p(61, 97), p(39, 97), p(35, 76)])
        torso.closeSubpath()
        pieces.append(torso)
        // Shoulders
        pieces.append(limb(p(31, 48), p(69, 48), width: 12 * s))
        // Trunks
        pieces.append(Path(
            roundedRect: CGRect(x: frame.minX + 36 * s, y: frame.minY + 92 * s, width: 28 * s, height: 22 * s),
            cornerRadius: 6 * s
        ))
        // Arms in guard: shoulder → elbow → glove
        pieces.append(limb(p(30, 49), p(15, 68), width: 11 * s))
        pieces.append(limb(p(15, 68), p(31, 37), width: 9.5 * s))
        pieces.append(limb(p(70, 49), p(85, 68), width: 11 * s))
        pieces.append(limb(p(85, 68), p(69, 37), width: 9.5 * s))
        // Legs: hip → knee → ankle → foot
        pieces.append(limb(p(43, 108), p(33, 149), width: 17 * s))
        pieces.append(limb(p(33, 149), p(28, 187), width: 11 * s))
        pieces.append(limb(p(21, 191), p(35, 192), width: 7 * s))
        pieces.append(limb(p(57, 108), p(68, 149), width: 17 * s))
        pieces.append(limb(p(68, 149), p(74, 187), width: 11 * s))
        pieces.append(limb(p(70, 192), p(84, 190), width: 7 * s))

        return pieces.dropFirst().reduce(pieces[0]) { $0.union($1) }
    }

    /// Capsule running from `a` to `b`.
    private func limb(_ a: CGPoint, _ b: CGPoint, width: CGFloat) -> Path {
        let length = max(hypot(b.x - a.x, b.y - a.y), width)
        let angle = atan2(b.y - a.y, b.x - a.x)
        let capsule = Path(
            roundedRect: CGRect(x: 0, y: -width / 2, width: length, height: width),
            cornerRadius: width / 2
        )
        let transform = CGAffineTransform(translationX: a.x, y: a.y).rotated(by: angle)
        return capsule.applying(transform)
    }
}

struct FighterGlovesShape: Shape {
    func path(in rect: CGRect) -> Path {
        let frame = SilhouetteGeometry.fittedRect(in: rect)
        let s = frame.width / SilhouetteGeometry.unitWidth
        var path = Path()
        for center in [CGPoint(x: 32, y: 31), CGPoint(x: 68, y: 30)] {
            let c = SilhouetteGeometry.point(center, in: frame)
            path.addEllipse(in: CGRect(x: c.x - 7.5 * s, y: c.y - 7 * s, width: 15 * s, height: 14 * s))
        }
        return path
    }
}

/// The custom fighter. `energy` (0…1) is the share of filled slots:
/// the outline glow intensifies as the build comes together.
struct FighterSilhouetteView: View {
    var energy: Double

    var body: some View {
        ZStack {
            Ellipse()
                .fill(GoatTheme.accent.opacity(0.10 + 0.18 * energy))
                .blur(radius: 40)
                .scaleEffect(x: 0.9, y: 0.75)

            FighterBodyShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x45454B), Color(hex: 0x222225), Color(hex: 0x111113)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            // Rim light from the upper left
            FighterBodyShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.10), .clear],
                        startPoint: .topLeading, endPoint: .center
                    )
                )

            FighterBodyShape()
                .stroke(GoatTheme.accent.opacity(0.30 + 0.6 * energy), lineWidth: 1.5)
                .shadow(color: GoatTheme.accent.opacity(0.25 + 0.55 * energy), radius: 4 + 10 * energy)

            FighterGlovesShape()
                .fill(GoatTheme.accentGradient)
                .shadow(color: GoatTheme.accent.opacity(0.7), radius: 8)
        }
        .animation(.easeInOut(duration: 0.6), value: energy)
        .accessibilityHidden(true)
    }
}
