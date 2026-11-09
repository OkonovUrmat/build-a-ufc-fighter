import SwiftUI
import GoatDomain

/// Right panel (regular width): division, overall rating, slot progress, spin status.
struct GameStatusPanel: View {
    let spinDivision: WeightClass?
    let customDivision: WeightClass?
    let rating: OverallRating?
    let filled: Int
    let total: Int
    let spinCount: Int
    let statusMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionLabel(title: "GAME STATUS")

            OverallRatingDisplay(rating: rating)

            SlotProgress(filled: filled, total: total)

            VStack(alignment: .leading, spacing: 10) {
                StatusRow(title: "THIS SPIN", value: spinDivision?.displayName.uppercased() ?? "—")
                StatusRow(title: "YOUR DIVISION", value: customDivision?.displayName.uppercased() ?? "SET BY SIZE PICK")
                StatusRow(title: "SPINS USED", value: "\(spinCount)")
                StatusRow(title: "REMAINING", value: "\(total - filled) SLOT\(total - filled == 1 ? "" : "S")")
            }

            Text(statusMessage)
                .font(GoatFont.label(13, weight: .semibold))
                .foregroundStyle(GoatTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .animation(.easeInOut, value: statusMessage)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .goatPanel()
    }
}

/// Compact status strip for iPhone portrait.
struct CompactStatusStrip: View {
    let rating: OverallRating?
    let filled: Int
    let total: Int
    let spinCount: Int
    let customDivision: WeightClass?

    var body: some View {
        HStack(spacing: 8) {
            StatTile(title: "OVERALL") {
                HStack(spacing: 6) {
                    Text(rating.map { "\($0.displayScore)" } ?? "--")
                        .font(GoatFont.number(20))
                        .foregroundStyle(GoatTheme.textPrimary)
                        .contentTransition(.numericText())
                    if let rating {
                        TierBadge(tier: rating.tier, size: .small)
                    }
                }
            }
            StatTile(title: "SLOTS") {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(filled)/\(total)")
                        .font(GoatFont.number(20))
                        .foregroundStyle(GoatTheme.textPrimary)
                        .contentTransition(.numericText())
                    ProgressSegments(filled: filled, total: total)
                }
            }
            StatTile(title: "DIVISION") {
                Text(customDivision.map { $0.baseName.uppercased() } ?? "VIA SIZE")
                    .font(GoatFont.display(15))
                    .foregroundStyle(customDivision == nil ? GoatTheme.textMuted : GoatTheme.accentBright)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filled)
    }
}

// MARK: - Building blocks

struct OverallRatingDisplay: View {
    let rating: OverallRating?

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text("OVERALL")
                    .font(GoatFont.label(11, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(GoatTheme.textSecondary)
                Text(rating.map { "\($0.displayScore)" } ?? "--")
                    .font(GoatFont.display(56))
                    .foregroundStyle(rating == nil ? GoatTheme.textMuted : GoatTheme.textPrimary)
                    .contentTransition(.numericText())
                    .shadow(color: GoatTheme.accent.opacity(rating == nil ? 0 : 0.35), radius: 12)
                if let rating, rating.isProvisional {
                    Text("PROVISIONAL · FILLED SLOTS ONLY")
                        .font(GoatFont.label(9, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(GoatTheme.textMuted)
                }
            }
            Spacer(minLength: 0)
            if let rating {
                TierBadge(tier: rating.tier, size: .large)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: rating?.displayScore)
    }
}

struct SlotProgress: View {
    let filled: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("SLOTS FILLED")
                    .font(GoatFont.label(11, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(GoatTheme.textSecondary)
                Spacer()
                Text("\(filled) / \(total)")
                    .font(GoatFont.number(14))
                    .foregroundStyle(GoatTheme.textPrimary)
                    .contentTransition(.numericText())
            }
            ProgressSegments(filled: filled, total: total)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filled)
    }
}

struct ProgressSegments: View {
    let filled: Int
    let total: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < filled ? AnyShapeStyle(GoatTheme.accentGradient) : AnyShapeStyle(Color.white.opacity(0.08)))
                    .frame(height: 5)
                    .shadow(color: index < filled ? GoatTheme.accent.opacity(0.6) : .clear, radius: 3)
            }
        }
    }
}

private struct StatusRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(GoatFont.label(11, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(GoatTheme.textMuted)
            Spacer()
            Text(value)
                .font(GoatFont.label(13, weight: .heavy))
                .foregroundStyle(GoatTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private struct StatTile<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(GoatFont.label(9.5, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(GoatTheme.textSecondary)
            content
        }
        .frame(maxWidth: .infinity, minHeight: 50, alignment: .topLeading)
        .goatPanel(padding: 10)
    }
}
