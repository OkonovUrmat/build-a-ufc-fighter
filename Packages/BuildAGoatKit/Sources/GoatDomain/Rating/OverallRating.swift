import Foundation

/// Configurable attribute weights. Must cover every attribute,
/// be non-negative, and sum to 1.0 (100%).
public struct AttributeWeights: Sendable, Hashable {
    public enum ValidationError: Error, Equatable, Sendable {
        case missing(FighterAttribute)
        case negative(FighterAttribute)
        case invalidTotal(Double)
    }

    private let storage: [FighterAttribute: Double]

    public init(_ weights: [FighterAttribute: Double]) throws {
        for attribute in FighterAttribute.allCases {
            guard let weight = weights[attribute] else { throw ValidationError.missing(attribute) }
            guard weight >= 0 else { throw ValidationError.negative(attribute) }
        }
        let total = weights.values.reduce(0, +)
        guard abs(total - 1.0) < 0.0001 else { throw ValidationError.invalidTotal(total) }
        self.storage = weights
    }

    /// Convenience for percentages, e.g. `[.striking: 12, ...]` summing to 100.
    public init(percentages: [FighterAttribute: Double]) throws {
        try self.init(percentages.mapValues { $0 / 100 })
    }

    private init(unchecked weights: [FighterAttribute: Double]) {
        self.storage = weights
    }

    public subscript(attribute: FighterAttribute) -> Double {
        storage[attribute] ?? 0
    }

    public var total: Double { storage.values.reduce(0, +) }

    /// Default MMA weighting from the design spec.
    public static let standard = AttributeWeights(unchecked: [
        .striking: 0.12,
        .power: 0.10,
        .kicking: 0.07,
        .wrestling: 0.12,
        .groundGame: 0.12,
        .speed: 0.08,
        .chin: 0.08,
        .cardio: 0.10,
        .fightIQ: 0.12,
        .size: 0.09,
    ])
}

public struct OverallRating: Sendable, Hashable {
    public let score: Double
    public let tier: Tier
    /// True while some slots are still empty (rating covers filled slots only).
    public let isProvisional: Bool

    public var displayScore: Int { Int(score.rounded()) }
}

/// Weighted overall rating with a "hole" penalty.
///
/// MMA punishes weaknesses: an elite striker with no takedown defence or a
/// glass chin gets found out. So on top of the weighted mean, every attribute
/// under `weaknessThreshold` subtracts points in proportion to its weight and
/// how far below the threshold it sits.
public struct OverallRatingCalculator: Sendable {
    public let weights: AttributeWeights
    public let weaknessThreshold: Int
    public let weaknessPenaltyRate: Double

    public init(
        weights: AttributeWeights = .standard,
        weaknessThreshold: Int = 70,
        weaknessPenaltyRate: Double = 0.6
    ) {
        self.weights = weights
        self.weaknessThreshold = weaknessThreshold
        self.weaknessPenaltyRate = weaknessPenaltyRate
    }

    /// Rates any subset of attributes; returns nil for an empty set.
    public func rating(for values: [FighterAttribute: Int]) -> OverallRating? {
        guard !values.isEmpty else { return nil }
        let totalWeight = values.keys.reduce(0.0) { $0 + weights[$1] }
        guard totalWeight > 0 else { return nil }

        let weightedSum = values.reduce(0.0) { $0 + Double($1.value) * weights[$1.key] }
        let mean = weightedSum / totalWeight

        let holeSum = values.reduce(0.0) { partial, entry in
            partial + Double(max(0, weaknessThreshold - entry.value)) * weights[entry.key]
        }
        let penalty = holeSum / totalWeight * weaknessPenaltyRate

        let score = min(max(mean - penalty, 0), 100)
        return OverallRating(
            score: score,
            tier: Tier(score: score),
            isProvisional: values.count < FighterAttribute.allCases.count
        )
    }

    public func rating(for attributes: FighterAttributes) -> OverallRating {
        // A full attribute set is never empty, so this cannot be nil.
        rating(for: attributes.values)!
    }

    public func rating(for session: GameSession) -> OverallRating? {
        rating(for: session.selections.mapValues(\.numericalValue))
    }
}
