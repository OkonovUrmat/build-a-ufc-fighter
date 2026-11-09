import Foundation

/// Random fighter draw: first a random division, then a random fighter in it.
///
/// Divisions are chosen uniformly among those that have at least one fighter,
/// so a thin division (e.g. Women's Featherweight) appears as often as a deep one.
/// Ordering is fixed (division enum order, fighters sorted by id) so that the
/// same seed always yields the same sequence.
public struct FighterSelectionEngine: Sendable {
    private struct DivisionPool: Sendable {
        let weightClass: WeightClass
        let fighters: [Fighter]
    }

    private let pools: [DivisionPool]
    private var rng: SeededRandomNumberGenerator

    public init(fighters: [Fighter], seed: UInt64) throws {
        let grouped = Dictionary(grouping: fighters, by: \.weightClass)
        let pools = WeightClass.allCases.compactMap { division -> DivisionPool? in
            guard let members = grouped[division], !members.isEmpty else { return nil }
            return DivisionPool(weightClass: division, fighters: members.sorted { $0.id < $1.id })
        }
        guard !pools.isEmpty else { throw GameError.noFighters }
        self.pools = pools
        self.rng = SeededRandomNumberGenerator(seed: seed)
    }

    public var availableDivisions: [WeightClass] { pools.map(\.weightClass) }

    public mutating func next() -> (weightClass: WeightClass, fighter: Fighter) {
        let pool = pools[rng.nextIndex(below: pools.count)]
        let fighter = pool.fighters[rng.nextIndex(below: pool.fighters.count)]
        return (pool.weightClass, fighter)
    }
}
