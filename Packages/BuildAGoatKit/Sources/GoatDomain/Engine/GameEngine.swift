import Foundation

public enum GameError: Error, Equatable, Sendable {
    case noFighters
    case gameComplete
    /// Tried to spin while the current fighter still awaits a pick.
    case selectionPending
    /// Tried to select before any spin.
    case noActiveSpin
    /// That slot was locked in on an earlier spin and cannot be replaced.
    case slotAlreadyFilled(FighterAttribute)
}

/// The rules of BUILD A GOAT, independent of any UI.
///
/// Loop: `spin()` → `select(_:)` → `spin()` → … until all ten slots are filled.
/// - The same fighter may appear on several spins.
/// - Each spin yields exactly one attribute.
/// - The pick on the current spin can be switched to another free slot
///   (protects against accidental taps). It locks in on the next spin.
/// - Slots locked in on earlier spins are permanent.
public struct GameEngine: Sendable {
    public private(set) var session: GameSession
    public let calculator: OverallRatingCalculator
    private var selector: FighterSelectionEngine

    public init(
        fighters: [Fighter],
        seed: UInt64,
        calculator: OverallRatingCalculator = OverallRatingCalculator()
    ) throws {
        self.selector = try FighterSelectionEngine(fighters: fighters, seed: seed)
        self.session = GameSession(seed: seed)
        self.calculator = calculator
    }

    public var phase: GameSession.Phase { session.phase }
    public var availableDivisions: [WeightClass] { selector.availableDivisions }

    public var overallRating: OverallRating? {
        calculator.rating(for: session)
    }

    /// True if tapping `attribute` would add it (or switch the current pick to it).
    public func canSelect(_ attribute: FighterAttribute) -> Bool {
        guard let spin = session.currentSpin else { return false }
        return spin.selectedAttribute != attribute && !isLocked(attribute)
    }

    /// Filled on an earlier spin — permanent.
    public func isLocked(_ attribute: FighterAttribute) -> Bool {
        guard let selection = session.selection(for: attribute) else { return false }
        return selection.spinNumber != session.currentSpin?.number
    }

    @discardableResult
    public mutating func spin() throws -> SpinResult {
        switch session.phase {
        case .complete: throw GameError.gameComplete
        case .awaitingSelection: throw GameError.selectionPending
        case .readyToSpin: break
        }
        let draw = selector.next()
        let result = SpinResult(
            number: session.spinCount + 1,
            weightClass: draw.weightClass,
            fighter: draw.fighter
        )
        session.record(result)
        return result
    }

    @discardableResult
    public mutating func select(_ attribute: FighterAttribute) throws -> AttributeSelection {
        guard let spin = session.currentSpin else { throw GameError.noActiveSpin }
        guard !isLocked(attribute) else { throw GameError.slotAlreadyFilled(attribute) }

        // Re-tapping the current pick changes nothing.
        if let existing = session.pendingSelection, existing.attribute == attribute {
            return existing
        }
        // Switching: free the slot picked earlier on this same spin.
        if let previous = spin.selectedAttribute {
            session.clear(previous)
        }

        let value = spin.fighter.attributes[attribute]
        let selection = AttributeSelection(
            attribute: attribute,
            tier: Tier(score: value),
            numericalValue: value,
            sourceFighterID: spin.fighter.id,
            sourceFighterName: spin.fighter.name,
            sourceWeightClass: spin.fighter.weightClass,
            spinNumber: spin.number
        )
        session.fill(selection)
        return selection
    }
}
