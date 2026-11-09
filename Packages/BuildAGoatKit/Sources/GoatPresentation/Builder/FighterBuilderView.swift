import SwiftUI
import GoatDomain

/// Main game screen. Three panels on iPad / wide screens,
/// stacked (status → board → fighter) on iPhone.
public struct FighterBuilderView: View {
    let viewModel: FighterBuilderViewModel
    let onSimulate: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirmNewGame = false

    public init(viewModel: FighterBuilderViewModel, onSimulate: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onSimulate = onSimulate
    }

    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                header
                if proxy.size.width >= 820 {
                    wideLayout(width: proxy.size.width)
                } else {
                    compactLayout(height: proxy.size.height)
                }
            }
        }
        .background(GoatBackground())
        .overlay(alignment: .top) {
            toastOverlay
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.toast)
        }
        .hiddenNavigationBar()
        .sensoryFeedback(.selection, trigger: viewModel.reelTick)
        .sensoryFeedback(.impact(weight: .heavy), trigger: viewModel.revealCount)
        .sensoryFeedback(.success, trigger: viewModel.selectionTick)
        .confirmationDialog("Start a new game?", isPresented: $confirmNewGame, titleVisibility: .visible) {
            Button("New Game", role: .destructive) {
                withAnimation(.spring) { viewModel.newGame() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current build will be lost.")
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(GoatTheme.card))
                    .overlay(Circle().strokeBorder(GoatTheme.stroke))
            }
            .accessibilityLabel("Back")

            Spacer()
            GoatWordmark(size: 22)
            Spacer()

            Button { confirmNewGame = true } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(GoatTheme.card))
                    .overlay(Circle().strokeBorder(GoatTheme.stroke))
            }
            .disabled(viewModel.spinCount == 0)
            .accessibilityLabel("New game")
        }
        .foregroundStyle(GoatTheme.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: Layouts

    private func compactLayout(height: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                CompactStatusStrip(
                    rating: viewModel.overallRating,
                    filled: viewModel.filledCount,
                    total: GameSession.totalSlots,
                    spinCount: viewModel.spinCount,
                    customDivision: viewModel.customWeightClass
                )

                board
                    .frame(height: min(max(height * 0.5, 340), 430))

                statusLine

                fighterPanel(style: .grid)

                DisclaimerFooter()
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            primaryAction
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 6)
                .background(
                    LinearGradient(
                        colors: [GoatTheme.background.opacity(0), GoatTheme.background.opacity(0.95), GoatTheme.background],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
        }
    }

    private func wideLayout(width: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ScrollView {
                fighterPanel(style: .list)
            }
            .scrollIndicators(.hidden)
            .frame(width: min(340, width * 0.31))

            board
                .padding(16)
                .goatPanel(padding: 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 16) {
                GameStatusPanel(
                    spinDivision: viewModel.currentSpin?.weightClass,
                    customDivision: viewModel.customWeightClass,
                    rating: viewModel.overallRating,
                    filled: viewModel.filledCount,
                    total: GameSession.totalSlots,
                    spinCount: viewModel.spinCount,
                    statusMessage: viewModel.statusMessage
                )
                Spacer(minLength: 0)
                primaryAction
                DisclaimerFooter()
            }
            .frame(width: min(280, width * 0.22))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: Pieces

    private var board: some View {
        CustomFighterBoard(slots: viewModel.slots, filledCount: viewModel.filledCount)
    }

    private func fighterPanel(style: CurrentFighterPanel.Style) -> some View {
        CurrentFighterPanel(
            spin: viewModel.currentSpin,
            fighterRating: viewModel.currentFighterRating,
            options: viewModel.options,
            reelFrame: viewModel.reelFrame,
            reelTick: viewModel.reelTick,
            style: style,
            onSelect: { attribute in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    viewModel.select(attribute)
                }
            }
        )
    }

    private var statusLine: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.isSpinning || viewModel.session.phase == .awaitingSelection ? GoatTheme.accent : GoatTheme.textMuted)
                .frame(width: 7, height: 7)
                .shadow(color: GoatTheme.accent, radius: viewModel.session.phase == .awaitingSelection ? 4 : 0)
            Text(viewModel.statusMessage)
                .font(GoatFont.label(13, weight: .semibold))
                .foregroundStyle(GoatTheme.textSecondary)
                .lineLimit(2)
                .contentTransition(.opacity)
            Spacer(minLength: 0)
        }
        .animation(.easeInOut, value: viewModel.statusMessage)
    }

    @ViewBuilder
    private var primaryAction: some View {
        if viewModel.isComplete {
            SpinButton(
                title: "SIMULATE CAREER",
                systemImage: "chart.line.uptrend.xyaxis",
                isEnabled: true,
                action: onSimulate
            )
            .transition(.scale.combined(with: .opacity))
        } else {
            SpinButton(
                title: viewModel.spinButtonTitle,
                systemImage: "arrow.triangle.2.circlepath",
                isEnabled: viewModel.canSpin,
                isBusy: viewModel.isSpinning,
                action: { viewModel.spin(reduceMotion: reduceMotion) }
            )
        }
    }

    @ViewBuilder
    private var toastOverlay: some View {
        if let toast = viewModel.toast {
            SelectionToastView(selection: toast.selection, switchedFrom: toast.switchedFrom)
                .padding(.top, 56)
                .transition(.move(edge: .top).combined(with: .opacity))
                .id(toast.id)
        }
    }
}

private struct SelectionToastView: View {
    let selection: AttributeSelection
    let switchedFrom: FighterAttribute?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: switchedFrom == nil ? "checkmark.seal.fill" : "arrow.left.arrow.right.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(GoatTheme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(switchedFrom.map { "SWITCHED: \($0.displayName) → \(selection.attribute.displayName)" }
                     ?? "\(selection.attribute.displayName) ADDED")
                    .font(GoatFont.display(15))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(GoatTheme.textPrimary)
                Text("from \(selection.sourceFighterName)")
                    .font(GoatFont.label(12, weight: .semibold))
                    .foregroundStyle(GoatTheme.textSecondary)
            }
            TierBadge(tier: selection.tier, size: .regular)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(GoatTheme.card))
        .overlay(Capsule().strokeBorder(GoatTheme.accentGradient, lineWidth: 1))
        .shadow(color: GoatTheme.accent.opacity(0.4), radius: 16)
        .accessibilityElement(children: .combine)
    }
}
