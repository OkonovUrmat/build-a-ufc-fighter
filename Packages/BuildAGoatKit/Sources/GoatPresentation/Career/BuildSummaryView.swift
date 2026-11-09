import SwiftUI
import GoatDomain

/// Phase 1 stand-in for the career simulation screen.
/// Shows the finished build with every attribute's source fighter;
/// the simulation, GOAT ranking and Fighter DNA arrive in Phase 3.
struct BuildSummaryView: View {
    let session: GameSession
    let rating: OverallRating?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(GoatTheme.card))
                    }
                    .foregroundStyle(GoatTheme.textPrimary)
                    Spacer()
                    GoatWordmark(size: 20)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("YOUR BUILD")
                        .font(GoatFont.display(36))
                        .foregroundStyle(GoatTheme.textPrimary)
                    if let division = session.weightClass {
                        DivisionChip(weightClass: division)
                    }
                }

                OverallRatingDisplay(rating: rating)
                    .goatPanel()

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(title: "ATTRIBUTE SOURCES")
                    ForEach(session.slots) { slot in
                        if let selection = slot.selection {
                            HStack(spacing: 10) {
                                Image(systemName: slot.attribute.symbolName)
                                    .foregroundStyle(GoatTheme.accent)
                                    .frame(width: 20)
                                Text(slot.attribute.displayName)
                                    .font(GoatFont.label(13, weight: .heavy))
                                    .foregroundStyle(GoatTheme.textPrimary)
                                Spacer()
                                Text(selection.sourceFighterName)
                                    .font(GoatFont.label(13, weight: .semibold))
                                    .foregroundStyle(GoatTheme.textSecondary)
                                    .lineLimit(1)
                                Text("\(selection.numericalValue)")
                                    .font(GoatFont.number(14))
                                    .foregroundStyle(GoatTheme.textPrimary)
                                TierBadge(tier: selection.tier, size: .small)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
                .goatPanel()

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(title: "CAREER SIMULATION")
                    Text("Coming in Phase 3: fictional career record, title runs, Fighter DNA comparisons and your GOAT ranking.")
                        .font(GoatFont.label(14, weight: .medium))
                        .foregroundStyle(GoatTheme.textSecondary)
                }
                .goatPanel(highlighted: true)

                DisclaimerFooter()
            }
            .padding(20)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(GoatBackground())
        .hiddenNavigationBar()
    }
}
