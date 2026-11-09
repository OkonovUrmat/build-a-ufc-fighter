import SwiftUI
import GoatDomain

// MARK: - Attribute icons

extension FighterAttribute {
    var symbolName: String {
        switch self {
        case .striking: return "figure.boxing"
        case .power: return "bolt.fill"
        case .kicking: return "figure.kickboxing"
        case .wrestling: return "figure.wrestling"
        case .groundGame: return "figure.martial.arts"
        case .speed: return "hare.fill"
        case .chin: return "shield.lefthalf.filled"
        case .cardio: return "heart.fill"
        case .fightIQ: return "brain.head.profile"
        case .size: return "ruler.fill"
        }
    }
}

// MARK: - Wordmark

struct GoatWordmark: View {
    var size: CGFloat = 22

    var body: some View {
        HStack(spacing: size * 0.18) {
            Text("BUILD A")
                .foregroundStyle(GoatTheme.textPrimary)
            Text("GOAT")
                .foregroundStyle(Color.white)
                .padding(.horizontal, size * 0.28)
                .padding(.vertical, size * 0.02)
                .background(SlantedBar().fill(GoatTheme.accentGradient))
                .shadow(color: GoatTheme.accent.opacity(0.6), radius: size * 0.35)
        }
        .font(GoatFont.display(size))
        .tracking(size * 0.04)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Build a GOAT")
    }
}

/// Broadcast-style slanted plate used behind key words.
struct SlantedBar: Shape {
    var slant: CGFloat = 0.18

    func path(in rect: CGRect) -> Path {
        let offset = rect.height * slant
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + offset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - offset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Primary action button

struct SpinButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    var isBusy = false
    let action: () -> Void

    @State private var breathing = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                TimelineView(.animation(paused: !isBusy)) { context in
                    let angle = isBusy
                        ? context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 0.75) / 0.75 * 360
                        : 0
                    Image(systemName: systemImage)
                        .font(.system(size: 19, weight: .black))
                        .rotationEffect(.degrees(angle))
                }
                Text(title)
                    .font(GoatFont.display(24))
                    .tracking(2.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isEnabled || isBusy ? Color.white : GoatTheme.textMuted)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background {
                Capsule().fill(
                    isEnabled
                        ? AnyShapeStyle(GoatTheme.accentGradient)
                        : AnyShapeStyle(GoatTheme.cardHighlight)
                )
            }
            .overlay {
                Capsule().strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(isEnabled ? 0.45 : 0.08), .clear],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            }
            .shadow(
                color: GoatTheme.accent.opacity(isEnabled ? (breathing ? 0.7 : 0.35) : 0),
                radius: breathing ? 24 : 12
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }
}

struct SecondaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(GoatFont.label(15, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(GoatTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Capsule().fill(GoatTheme.card))
                .overlay(Capsule().strokeBorder(GoatTheme.strokeStrong, lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Fighter portrait

/// Placeholder portrait: monogram on a glowing disc with the nationality flag.
/// Swap for licensed artwork once available.
struct FighterPortrait: View {
    let fighter: Fighter
    var size: CGFloat = 64

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle().fill(
                    RadialGradient(
                        colors: [Color(hex: 0x3A1212), GoatTheme.card],
                        center: .top, startRadius: 2, endRadius: size
                    )
                )
                Image(systemName: "figure.boxing")
                    .font(.system(size: size * 0.62, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.06))
                Text(fighter.initials)
                    .font(GoatFont.display(size * 0.38))
                    .foregroundStyle(GoatTheme.textPrimary)
            }
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(GoatTheme.accentGradient, lineWidth: 2))
            .shadow(color: GoatTheme.accent.opacity(0.4), radius: 10)

            Text(fighter.nationality.flagEmoji)
                .font(.system(size: size * 0.26))
                .padding(3)
                .background(Circle().fill(GoatTheme.background))
                .offset(x: 4, y: 4)
        }
        .accessibilityHidden(true)
    }
}

struct DivisionChip: View {
    let weightClass: WeightClass

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: weightClass.gender == .women ? "figure.stand.dress" : "figure.stand")
                .font(.system(size: 10, weight: .bold))
            Text(weightClass.displayName.uppercased())
                .font(GoatFont.label(11, weight: .heavy))
                .tracking(1)
            Text("· \(weightClass.limitPounds) LB")
                .font(GoatFont.label(11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.75))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(GoatTheme.accentGradient))
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
    }
}

struct DisclaimerFooter: View {
    var body: some View {
        Text("Ratings are fictional expert-style estimates, not official UFC data. Not affiliated with the UFC.")
            .font(GoatFont.label(10, weight: .medium))
            .foregroundStyle(GoatTheme.textMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}
