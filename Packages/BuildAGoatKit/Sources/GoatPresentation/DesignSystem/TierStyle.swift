import SwiftUI
import GoatDomain

/// Each tier family has its own look: S is white "champion" with red glow,
/// A is solid red, B is silver on charcoal, C is cold grey, D is dim black.
extension Tier {
    var fill: AnyShapeStyle {
        switch self {
        case .s: return AnyShapeStyle(GoatTheme.championWhite)
        case .aPlus: return AnyShapeStyle(Color(hex: 0xE10600))
        case .a: return AnyShapeStyle(Color(hex: 0xBE0909))
        case .aMinus: return AnyShapeStyle(Color(hex: 0x960B0B))
        case .bPlus, .b, .bMinus: return AnyShapeStyle(Color(hex: 0x2A2A2E))
        case .cPlus, .c, .cMinus: return AnyShapeStyle(Color(hex: 0x1C1C1F))
        case .d: return AnyShapeStyle(Color(hex: 0x0E0E0F))
        }
    }

    var textColor: Color {
        switch self {
        case .s: return GoatTheme.accent
        case .aPlus, .a, .aMinus: return .white
        case .bPlus: return Color(hex: 0xF2F2F2)
        case .b: return Color(hex: 0xDADADD)
        case .bMinus: return Color(hex: 0xBDBDC2)
        case .cPlus, .c, .cMinus: return Color(hex: 0x8E8E93)
        case .d: return Color(hex: 0x5C5C62)
        }
    }

    var borderColor: Color {
        switch self {
        case .s: return .white
        case .aPlus, .a, .aMinus: return Color(hex: 0xFF4D4D).opacity(0.6)
        case .bPlus, .b, .bMinus: return Color.white.opacity(0.35)
        case .cPlus, .c, .cMinus: return Color.white.opacity(0.12)
        case .d: return GoatTheme.accent.opacity(0.25)
        }
    }

    var glowColor: Color {
        switch self {
        case .s: return GoatTheme.accent.opacity(0.85)
        case .aPlus: return GoatTheme.accent.opacity(0.45)
        default: return .clear
        }
    }

    /// Bar colour used for rating meters.
    var meterColor: Color {
        switch self {
        case .s: return GoatTheme.championWhite
        case .aPlus, .a, .aMinus: return GoatTheme.accent
        case .bPlus, .b, .bMinus: return Color(hex: 0xCFCFD4)
        case .cPlus, .c, .cMinus: return Color(hex: 0x6E6E73)
        case .d: return Color(hex: 0x3F3F44)
        }
    }
}

struct TierBadge: View {
    enum Size {
        case small, regular, large

        var font: CGFloat {
            switch self {
            case .small: return 12
            case .regular: return 16
            case .large: return 26
            }
        }

        var minWidth: CGFloat {
            switch self {
            case .small: return 24
            case .regular: return 34
            case .large: return 54
            }
        }

        var height: CGFloat {
            switch self {
            case .small: return 18
            case .regular: return 26
            case .large: return 42
            }
        }
    }

    let tier: Tier
    var size: Size = .regular

    var body: some View {
        Text(tier.label)
            .font(GoatFont.display(size.font))
            .foregroundStyle(tier.textColor)
            .padding(.horizontal, 4)
            .frame(minWidth: size.minWidth, minHeight: size.height)
            .background(RoundedRectangle(cornerRadius: size == .large ? 10 : 5, style: .continuous).fill(tier.fill))
            .overlay(
                RoundedRectangle(cornerRadius: size == .large ? 10 : 5, style: .continuous)
                    .strokeBorder(tier.borderColor, lineWidth: 1)
            )
            .shadow(color: tier.glowColor, radius: size == .small ? 4 : 10)
            .accessibilityLabel("Tier \(tier.label)")
    }
}

struct RatingMeter: View {
    let value: Int

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.06))
                Capsule()
                    .fill(Tier(score: value).meterColor)
                    .frame(width: proxy.size.width * CGFloat(value) / 100)
            }
        }
        .frame(height: 4)
    }
}
