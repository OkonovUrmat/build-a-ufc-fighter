import SwiftUI
import GoatDomain

struct HomeView: View {
    let continueProgress: Int?
    let rosterCount: Int
    let onNewGame: () -> Void
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            GoatBackground()

            ScrollView {
                VStack(spacing: 28) {
                    hero
                    actions
                    HowItWorks()
                    DisclaimerFooter()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .hiddenNavigationBar()
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) { appeared = true }
        }
    }

    private var hero: some View {
        VStack(spacing: 18) {
            FighterSilhouetteView(energy: appeared ? 0.55 : 0)
                .frame(width: 130, height: 260)
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)

            GoatWordmark(size: 46)

            Text("Draft one attribute from each legend.\nBuild the greatest fighter of all time.")
                .font(GoatFont.label(16, weight: .semibold))
                .foregroundStyle(GoatTheme.textSecondary)
                .multilineTextAlignment(.center)

            Text("\(rosterCount) LEGENDS · 12 DIVISIONS · 10 SLOTS")
                .font(GoatFont.label(11, weight: .heavy))
                .tracking(1.8)
                .foregroundStyle(GoatTheme.accent)
        }
        .padding(.top, 8)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            SpinButton(title: "NEW GAME", systemImage: "bolt.fill", isEnabled: true, action: onNewGame)
            if let continueProgress {
                SecondaryButton(
                    title: "CONTINUE BUILD  \(continueProgress)/\(GameSession.totalSlots)",
                    systemImage: "play.fill",
                    action: onContinue
                )
            }
        }
    }
}

private struct HowItWorks: View {
    private let steps: [(icon: String, title: String, text: String)] = [
        ("arrow.triangle.2.circlepath", "SPIN", "A random division, then a random legend from it."),
        ("hand.tap.fill", "DRAFT", "Take one attribute. Switch freely until your next spin locks it in."),
        ("figure.boxing", "BUILD", "Fill all 10 slots, then simulate a fictional career."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(title: "HOW IT WORKS")
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle().fill(GoatTheme.accent.opacity(0.14))
                        Image(systemName: step.icon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(GoatTheme.accent)
                    }
                    .frame(width: 38, height: 38)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(index + 1). \(step.title)")
                            .font(GoatFont.display(17))
                            .foregroundStyle(GoatTheme.textPrimary)
                        Text(step.text)
                            .font(GoatFont.label(14, weight: .medium))
                            .foregroundStyle(GoatTheme.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .goatPanel()
    }
}
