import Foundation

/// One attribute permanently drafted into the custom fighter.
/// Always remembers which fighter it came from.
public struct AttributeSelection: Sendable, Hashable, Codable {
    public let attribute: FighterAttribute
    public let tier: Tier
    public let numericalValue: Int
    public let sourceFighterID: String
    public let sourceFighterName: String
    public let sourceWeightClass: WeightClass
    public let spinNumber: Int

    public init(
        attribute: FighterAttribute, tier: Tier, numericalValue: Int,
        sourceFighterID: String, sourceFighterName: String,
        sourceWeightClass: WeightClass, spinNumber: Int
    ) {
        self.attribute = attribute
        self.tier = tier
        self.numericalValue = numericalValue
        self.sourceFighterID = sourceFighterID
        self.sourceFighterName = sourceFighterName
        self.sourceWeightClass = sourceWeightClass
        self.spinNumber = spinNumber
    }
}

/// A slot on the custom fighter: empty or holding exactly one selection.
public struct AttributeSlot: Sendable, Hashable, Identifiable {
    public let attribute: FighterAttribute
    public let selection: AttributeSelection?

    public var id: FighterAttribute { attribute }
    public var isFilled: Bool { selection != nil }

    public init(attribute: FighterAttribute, selection: AttributeSelection?) {
        self.attribute = attribute
        self.selection = selection
    }
}

/// The outcome of one spin: a random division and a random fighter from it.
public struct SpinResult: Sendable, Hashable, Codable {
    public let number: Int
    public let weightClass: WeightClass
    public let fighter: Fighter
    /// The single attribute taken from this fighter, once chosen.
    public internal(set) var selectedAttribute: FighterAttribute?

    public init(number: Int, weightClass: WeightClass, fighter: Fighter, selectedAttribute: FighterAttribute? = nil) {
        self.number = number
        self.weightClass = weightClass
        self.fighter = fighter
        self.selectedAttribute = selectedAttribute
    }
}

public struct GameSession: Sendable, Codable, Identifiable {
    public enum Phase: Sendable, Equatable {
        /// No pending spin — the player may spin.
        case readyToSpin
        /// A fighter is on screen and the player must take one attribute.
        case awaitingSelection
        /// All slots are filled.
        case complete
    }

    public let id: UUID
    public let seed: UInt64
    public let startedAt: Date
    public private(set) var selections: [FighterAttribute: AttributeSelection]
    public private(set) var spins: [SpinResult]

    public init(id: UUID = UUID(), seed: UInt64, startedAt: Date = .now) {
        self.id = id
        self.seed = seed
        self.startedAt = startedAt
        self.selections = [:]
        self.spins = []
    }

    public static let totalSlots = FighterAttribute.allCases.count

    public var currentSpin: SpinResult? { spins.last }
    public var spinCount: Int { spins.count }
    public var filledCount: Int { selections.count }
    public var remainingCount: Int { Self.totalSlots - filledCount }
    public var isComplete: Bool { filledCount == Self.totalSlots }

    public var phase: Phase {
        if isComplete { return .complete }
        if let spin = currentSpin, spin.selectedAttribute == nil { return .awaitingSelection }
        return .readyToSpin
    }

    /// Slots in canonical attribute order.
    public var slots: [AttributeSlot] {
        FighterAttribute.allCases.map { AttributeSlot(attribute: $0, selection: selections[$0]) }
    }

    public func selection(for attribute: FighterAttribute) -> AttributeSelection? {
        selections[attribute]
    }

    public func isFilled(_ attribute: FighterAttribute) -> Bool {
        selections[attribute] != nil
    }

    /// The custom fighter competes in the division of whoever supplied SIZE.
    public var weightClass: WeightClass? {
        selections[.size]?.sourceWeightClass
    }

    // MARK: Mutation — only the engine (same module) may change a session.

    mutating func record(_ spin: SpinResult) {
        spins.append(spin)
    }

    mutating func fill(_ selection: AttributeSelection) {
        selections[selection.attribute] = selection
        if !spins.isEmpty {
            spins[spins.count - 1].selectedAttribute = selection.attribute
        }
    }

    mutating func clear(_ attribute: FighterAttribute) {
        selections.removeValue(forKey: attribute)
        if let last = spins.indices.last, spins[last].selectedAttribute == attribute {
            spins[last].selectedAttribute = nil
        }
    }

    /// The pick made on the current spin, if any. It stays changeable until the next spin.
    public var pendingSelection: AttributeSelection? {
        guard let attribute = currentSpin?.selectedAttribute else { return nil }
        return selections[attribute]
    }
}
