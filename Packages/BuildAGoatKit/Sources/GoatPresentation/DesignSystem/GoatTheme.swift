import SwiftUI

/// BUILD A GOAT visual identity: fight-night broadcast — black canvas, red energy, white type.
public enum GoatTheme {
    // Surfaces
    public static let background = Color(hex: 0x09090A)
    public static let backgroundRaised = Color(hex: 0x111113)
    public static let card = Color(hex: 0x161618)
    public static let cardHighlight = Color(hex: 0x202023)
    public static let stroke = Color.white.opacity(0.07)
    public static let strokeStrong = Color.white.opacity(0.14)

    // Accents
    public static let accent = Color(hex: 0xD20A0A)       // fight-night red
    public static let accentDark = Color(hex: 0x7A0606)
    public static let accentBright = Color(hex: 0xFF3B3B)
    public static let championWhite = Color(hex: 0xF5F5F5)

    // Text
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: 0x9A9AA0)
    public static let textMuted = Color(hex: 0x5C5C62)

    public static var accentGradient: LinearGradient {
        LinearGradient(colors: [accentBright, accent, accentDark], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    public static var cardGradient: LinearGradient {
        LinearGradient(colors: [cardHighlight, card], startPoint: .top, endPoint: .bottom)
    }

    public static var filledSlotGradient: LinearGradient {
        LinearGradient(
            colors: [accent.opacity(0.32), Color(hex: 0x2A0E0E), card],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

/// Condensed, heavy, italic display type for a broadcast-graphics feel.
public enum GoatFont {
    public static func display(_ size: CGFloat, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight).width(.condensed).italic()
    }

    public static func label(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight).width(.condensed)
    }

    public static func number(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded).monospacedDigit()
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Screen background

/// Deep gradient + faint dashboard grid + top red bloom.
struct GoatBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x141416), GoatTheme.background, Color(hex: 0x040404)],
                startPoint: .top, endPoint: .bottom
            )
            Canvas { context, size in
                let spacing: CGFloat = 28
                var grid = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: size.height))
                    x += spacing
                }
                var y: CGFloat = 0
                while y <= size.height {
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                    y += spacing
                }
                context.stroke(grid, with: .color(.white.opacity(0.022)), lineWidth: 0.5)
            }
            RadialGradient(
                colors: [GoatTheme.accent.opacity(0.20), .clear],
                center: .top, startRadius: 10, endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Panels

struct GoatPanelModifier: ViewModifier {
    var padding: CGFloat
    var highlighted: Bool

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(GoatTheme.cardGradient)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        highlighted ? AnyShapeStyle(GoatTheme.accentGradient) : AnyShapeStyle(GoatTheme.stroke),
                        lineWidth: 1
                    )
            }
    }
}

extension View {
    func goatPanel(padding: CGFloat = 16, highlighted: Bool = false) -> some View {
        modifier(GoatPanelModifier(padding: padding, highlighted: highlighted))
    }

    @ViewBuilder
    func hiddenNavigationBar() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }
}

struct SectionLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(GoatTheme.accent)
                .frame(width: 3, height: 12)
            Text(title)
                .font(GoatFont.label(11, weight: .heavy))
                .tracking(1.6)
                .foregroundStyle(GoatTheme.textSecondary)
        }
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
