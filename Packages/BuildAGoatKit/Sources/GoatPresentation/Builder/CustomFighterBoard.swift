import SwiftUI
import GoatDomain

/// Positions for the centre board: five slot cards per side, the silhouette
/// in the middle, and connector lines from each card to its body region.
struct BoardLayout {
    static let leftColumn: [FighterAttribute] = [.fightIQ, .striking, .chin, .wrestling, .kicking]
    static let rightColumn: [FighterAttribute] = [.size, .power, .cardio, .groundGame, .speed]

    let size: CGSize

    /// Area actually used: tall, narrow containers (iPad centre panel) are capped
    /// so the silhouette stays large and connector lines stay short.
    var frame: CGRect {
        let height = min(size.height, size.width * 1.35)
        return CGRect(x: 0, y: (size.height - height) / 2, width: size.width, height: height)
    }

    var cardSize: CGSize {
        let width = min(max(size.width * 0.29, 98), 156)
        let height = min(max((frame.height - 4 * 8) / 5, 54), 80)
        return CGSize(width: width, height: height)
    }

    func isLeft(_ attribute: FighterAttribute) -> Bool {
        Self.leftColumn.contains(attribute)
    }

    func cardCenter(_ attribute: FighterAttribute) -> CGPoint {
        let left = isLeft(attribute)
        let column = left ? Self.leftColumn : Self.rightColumn
        let index = CGFloat(column.firstIndex(of: attribute) ?? 0)
        let step = (frame.height - cardSize.height) / CGFloat(max(column.count - 1, 1))
        let y = frame.minY + cardSize.height / 2 + index * step
        let x = left ? cardSize.width / 2 : size.width - cardSize.width / 2
        return CGPoint(x: x, y: y)
    }

    func cardEdge(_ attribute: FighterAttribute) -> CGPoint {
        let center = cardCenter(attribute)
        let x = isLeft(attribute) ? cardSize.width : size.width - cardSize.width
        return CGPoint(x: x, y: center.y)
    }

    var silhouetteRect: CGRect {
        let inset = cardSize.width + 14
        let available = CGRect(x: inset, y: frame.minY + 4, width: max(size.width - inset * 2, 40), height: frame.height - 8)
        return SilhouetteGeometry.fittedRect(in: available)
    }

    func anchor(_ attribute: FighterAttribute) -> CGPoint {
        SilhouetteGeometry.point(SilhouetteGeometry.anchor(for: attribute), in: silhouetteRect)
    }
}

/// Elbowed connector: short horizontal run out of the card, then straight to the body.
struct ConnectorShape: Shape {
    var start: CGPoint
    var end: CGPoint
    var fromLeft: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: CGPoint(x: start.x + (fromLeft ? 10 : -10), y: start.y))
        path.addLine(to: end)
        return path
    }
}

struct CustomFighterBoard: View {
    let slots: [AttributeSlot]
    let filledCount: Int

    var body: some View {
        GeometryReader { proxy in
            let layout = BoardLayout(size: proxy.size)
            let silhouette = layout.silhouetteRect

            ZStack(alignment: .topLeading) {
                FighterSilhouetteView(energy: Double(filledCount) / Double(GameSession.totalSlots))
                    .frame(width: silhouette.width, height: silhouette.height)
                    .position(x: silhouette.midX, y: silhouette.midY)

                ForEach(slots) { slot in
                    connector(for: slot, layout: layout)
                }

                ForEach(slots) { slot in
                    AttributeSlotCard(slot: slot, alignLeading: layout.isLeft(slot.attribute))
                        .frame(width: layout.cardSize.width, height: layout.cardSize.height)
                        .position(layout.cardCenter(slot.attribute))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your custom fighter")
    }

    @ViewBuilder
    private func connector(for slot: AttributeSlot, layout: BoardLayout) -> some View {
        let shape = ConnectorShape(
            start: layout.cardEdge(slot.attribute),
            end: layout.anchor(slot.attribute),
            fromLeft: layout.isLeft(slot.attribute)
        )
        let anchor = layout.anchor(slot.attribute)

        ZStack(alignment: .topLeading) {
            shape
                .stroke(GoatTheme.textMuted.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

            shape
                .trim(from: 0, to: slot.isFilled ? 1 : 0)
                .stroke(GoatTheme.accent, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .shadow(color: GoatTheme.accent.opacity(0.9), radius: 4)
                .animation(.easeOut(duration: 0.55), value: slot.isFilled)

            AnchorDot(isActive: slot.isFilled)
                .position(anchor)
        }
        .allowsHitTesting(false)
    }
}

private struct AnchorDot: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .fill(GoatTheme.accent.opacity(0.35))
                    .frame(width: 14, height: 14)
                    .phaseAnimator([1.0, 1.6]) { content, scale in
                        content.scaleEffect(scale).opacity(2 - scale)
                    } animation: { _ in .easeInOut(duration: 1.4) }
            }
            Circle()
                .fill(isActive ? GoatTheme.accent : GoatTheme.textMuted)
                .frame(width: 6, height: 6)
                .shadow(color: isActive ? GoatTheme.accent : .clear, radius: 4)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isActive)
    }
}

/// One slot around the silhouette: empty placeholder or the drafted attribute.
struct AttributeSlotCard: View {
    let slot: AttributeSlot
    let alignLeading: Bool

    private var horizontalAlignment: HorizontalAlignment { alignLeading ? .leading : .trailing }
    private var frameAlignment: Alignment { alignLeading ? .topLeading : .topTrailing }

    var body: some View {
        VStack(alignment: horizontalAlignment, spacing: 3) {
            HStack(spacing: 4) {
                if !alignLeading { Spacer(minLength: 0) }
                Image(systemName: slot.attribute.symbolName)
                    .font(.system(size: 9, weight: .bold))
                Text(slot.attribute.displayName)
                    .font(GoatFont.label(10.5, weight: .heavy))
                    .tracking(0.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if alignLeading { Spacer(minLength: 0) }
            }
            .foregroundStyle(slot.isFilled ? Color.white : GoatTheme.textSecondary)

            if let selection = slot.selection {
                HStack(spacing: 6) {
                    TierBadge(tier: selection.tier, size: .small)
                    Text("\(selection.numericalValue)")
                        .font(GoatFont.number(15))
                        .foregroundStyle(GoatTheme.textPrimary)
                }
                Text(selection.sourceFighterName.uppercased())
                    .font(GoatFont.label(9.5, weight: .semibold))
                    .foregroundStyle(GoatTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                Text("EMPTY")
                    .font(GoatFont.display(14))
                    .foregroundStyle(GoatTheme.textMuted)
                Text("Awaiting pick")
                    .font(GoatFont.label(9.5, weight: .medium))
                    .foregroundStyle(GoatTheme.textMuted)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(slot.isFilled ? AnyShapeStyle(GoatTheme.filledSlotGradient) : AnyShapeStyle(GoatTheme.card.opacity(0.9)))
        }
        .overlay {
            if slot.isFilled {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(GoatTheme.accentGradient, lineWidth: 1.2)
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(GoatTheme.strokeStrong, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .shadow(color: slot.isFilled ? GoatTheme.accent.opacity(0.35) : .clear, radius: 10)
        // Pop + flash when this slot gets filled.
        .phaseAnimator([false, true], trigger: slot.selection?.spinNumber) { content, pop in
            content
                .scaleEffect(pop ? 1.1 : 1)
                .brightness(pop ? 0.15 : 0)
        } animation: { pop in
            pop ? .spring(response: 0.22, dampingFraction: 0.55) : .spring(response: 0.4, dampingFraction: 0.8)
        }
        .animation(.easeInOut(duration: 0.3), value: slot.isFilled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if let selection = slot.selection {
            return "\(slot.attribute.displayName), tier \(selection.tier.label), \(selection.numericalValue), from \(selection.sourceFighterName)"
        }
        return "\(slot.attribute.displayName), empty"
    }
}
