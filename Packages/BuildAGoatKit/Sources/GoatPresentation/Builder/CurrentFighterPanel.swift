import SwiftUI
import GoatDomain

/// Left panel: the fighter drawn on this spin, with every attribute tappable.
struct CurrentFighterPanel: View {
    enum Style { case list, grid }

    let spin: SpinResult?
    let fighterRating: OverallRating?
    let options: [AttributeOption]
    let reelFrame: ReelFrame?
    let reelTick: Int
    let style: Style
    let onSelect: (FighterAttribute) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(title: "CURRENT FIGHTER")

            if let reelFrame {
                SpinReelView(frame: reelFrame, tick: reelTick)
            } else if let spin {
                FighterHeader(spin: spin, rating: fighterRating)
                    .transition(.asymmetric(insertion: .scale(scale: 0.92).combined(with: .opacity), removal: .opacity))
                attributeOptions
            } else {
                EmptyFighterState()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .goatPanel(highlighted: spin?.selectedAttribute == nil && spin != nil && reelFrame == nil)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: spin?.number)
    }

    @ViewBuilder
    private var attributeOptions: some View {
        switch style {
        case .list:
            VStack(spacing: 6) {
                ForEach(options) { option in
                    AttributeOptionButton(option: option, style: .row) { onSelect(option.attribute) }
                }
            }
        case .grid:
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(options) { option in
                    AttributeOptionButton(option: option, style: .chip) { onSelect(option.attribute) }
                }
            }
        }
    }
}

// MARK: - Header

private struct FighterHeader: View {
    let spin: SpinResult
    let rating: OverallRating?

    private var fighter: Fighter { spin.fighter }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                FighterPortrait(fighter: fighter, size: 64)

                VStack(alignment: .leading, spacing: 3) {
                    if let nickname = fighter.nickname {
                        Text("“\(nickname.uppercased())”")
                            .font(GoatFont.label(11, weight: .heavy))
                            .tracking(1)
                            .foregroundStyle(GoatTheme.accent)
                            .lineLimit(1)
                    }
                    Text(fighter.name.uppercased())
                        .font(GoatFont.display(24))
                        .foregroundStyle(GoatTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                    HStack(spacing: 6) {
                        Text("\(fighter.nationality.flagEmoji) \(fighter.nationality.name)")
                        Text("•")
                        Text(fighter.record.display)
                            .font(GoatFont.number(12))
                    }
                    .font(GoatFont.label(12, weight: .semibold))
                    .foregroundStyle(GoatTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 0)

                if let rating {
                    VStack(spacing: 3) {
                        TierBadge(tier: rating.tier, size: .regular)
                        Text("OVR \(rating.displayScore)")
                            .font(GoatFont.label(10, weight: .heavy))
                            .foregroundStyle(GoatTheme.textSecondary)
                    }
                }
            }

            HStack {
                DivisionChip(weightClass: fighter.weightClass)
                Spacer()
                Text("SPIN #\(spin.number)")
                    .font(GoatFont.label(11, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(GoatTheme.textMuted)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Option button

private struct AttributeOptionButton: View {
    enum Style { case row, chip }

    let option: AttributeOption
    let style: Style
    let action: () -> Void

    private var isChosen: Bool { option.state == .chosen }
    private var isDimmed: Bool { !option.isSelectable && !isChosen }

    var body: some View {
        Button(action: action) {
            Group {
                switch style {
                case .row: rowContent
                case .chip: chipContent
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isChosen ? AnyShapeStyle(GoatTheme.filledSlotGradient) : AnyShapeStyle(GoatTheme.cardHighlight))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isChosen ? AnyShapeStyle(GoatTheme.accentGradient) : AnyShapeStyle(GoatTheme.stroke),
                        lineWidth: isChosen ? 1.5 : 1
                    )
            }
            .shadow(color: isChosen ? GoatTheme.accent.opacity(0.55) : .clear, radius: 12)
            .opacity(isDimmed ? 0.42 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!option.isSelectable)
        .phaseAnimator([false, true], trigger: isChosen) { content, pop in
            content.scaleEffect(pop && isChosen ? 1.05 : 1)
        } animation: { _ in .spring(response: 0.25, dampingFraction: 0.6) }
        .animation(.easeInOut(duration: 0.25), value: option.state)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(option.state == .available ? "Adds this attribute to your fighter" : option.state == .switchable ? "Moves this spin's pick here" : "")
    }

    private var rowContent: some View {
        HStack(spacing: 10) {
            Image(systemName: option.attribute.symbolName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isChosen ? GoatTheme.accent : GoatTheme.textSecondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text(option.attribute.displayName)
                    .font(GoatFont.label(13, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(GoatTheme.textPrimary)
                stateCaption
            }
            Spacer(minLength: 6)
            RatingMeter(value: option.value)
                .frame(width: 54)
            Text("\(option.value)")
                .font(GoatFont.number(15))
                .foregroundStyle(GoatTheme.textPrimary)
                .frame(width: 28, alignment: .trailing)
            TierBadge(tier: option.tier, size: .small)
            stateIcon
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 46)
    }

    private var chipContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: option.attribute.symbolName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isChosen ? GoatTheme.accent : GoatTheme.textSecondary)
                Text(option.attribute.displayName)
                    .font(GoatFont.label(11, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(GoatTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                stateIcon
            }
            HStack(spacing: 7) {
                TierBadge(tier: option.tier, size: .small)
                Text("\(option.value)")
                    .font(GoatFont.number(15))
                    .foregroundStyle(GoatTheme.textPrimary)
                RatingMeter(value: option.value)
            }
            stateCaption
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
    }

    @ViewBuilder
    private var stateCaption: some View {
        switch option.state {
        case .available:
            Text("TAP TO DRAFT")
                .font(GoatFont.label(9, weight: .heavy))
                .tracking(1)
                .foregroundStyle(GoatTheme.accent.opacity(0.85))
        case .chosen:
            Text("ADDED · TAP ANOTHER TO SWITCH")
                .font(GoatFont.label(9, weight: .heavy))
                .tracking(1)
                .foregroundStyle(GoatTheme.accentBright)
        case .alreadyFilled(let source):
            Text("FILLED · \(source.uppercased())")
                .font(GoatFont.label(9, weight: .bold))
                .foregroundStyle(GoatTheme.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        case .switchable:
            Text("TAP TO SWITCH")
                .font(GoatFont.label(9, weight: .heavy))
                .tracking(1)
                .foregroundStyle(GoatTheme.textSecondary)
        }
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch option.state {
        case .available:
            Image(systemName: "plus.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GoatTheme.accent)
        case .chosen:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(GoatTheme.accent)
                .symbolEffect(.bounce, value: isChosen)
        case .switchable:
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GoatTheme.textSecondary)
        case .alreadyFilled:
            Image(systemName: "lock.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(GoatTheme.textMuted)
        }
    }

    private var accessibilityText: String {
        let base = "\(option.attribute.displayName), \(option.value), tier \(option.tier.label)"
        switch option.state {
        case .available: return base
        case .chosen: return "\(base), added to your fighter"
        case .alreadyFilled(let source): return "\(base), slot already filled by \(source)"
        case .switchable: return "\(base), tap to switch your pick to this attribute"
        }
    }
}

// MARK: - Reel & empty state

private struct SpinReelView: View {
    let frame: ReelFrame
    let tick: Int

    var body: some View {
        VStack(spacing: 10) {
            Text("SPINNING")
                .font(GoatFont.label(11, weight: .heavy))
                .tracking(4)
                .foregroundStyle(GoatTheme.accent)

            ZStack {
                Text(frame.weightClass.displayName.uppercased())
                    .id("division-\(tick)")
                    .transition(.push(from: .bottom))
            }
            .font(GoatFont.label(14, weight: .heavy))
            .tracking(1.5)
            .foregroundStyle(GoatTheme.textSecondary)
            .clipped()

            ZStack {
                Text(frame.fighterName.uppercased())
                    .id("name-\(tick)")
                    .transition(.push(from: .bottom))
            }
            .font(GoatFont.display(32))
            .foregroundStyle(GoatTheme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .blur(radius: 0.8)
            .frame(height: 44)
            .clipped()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(GoatTheme.background.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(GoatTheme.accent.opacity(0.4), lineWidth: 1)
                )
        )
        .animation(.easeOut(duration: 0.09), value: tick)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Spinning")
    }
}

private struct EmptyFighterState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.boxing")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(GoatTheme.accentGradient)
            Text("PRESS SPIN TO DRAW YOUR FIRST LEGEND")
                .font(GoatFont.display(18))
                .foregroundStyle(GoatTheme.textPrimary)
                .multilineTextAlignment(.center)
            Text("Random division → random fighter → you take ONE attribute. Fill all 10 slots to build your GOAT.")
                .font(GoatFont.label(13, weight: .medium))
                .foregroundStyle(GoatTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}
