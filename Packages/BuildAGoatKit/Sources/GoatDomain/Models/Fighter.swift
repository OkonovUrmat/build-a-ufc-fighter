import Foundation

/// 0–100 ratings for every attribute of a historical fighter.
/// Values are clamped to 0...100 on creation.
public struct FighterAttributes: Sendable, Hashable, Codable {
    public let striking: Int
    public let power: Int
    public let kicking: Int
    public let wrestling: Int
    public let groundGame: Int
    public let speed: Int
    public let chin: Int
    public let cardio: Int
    public let fightIQ: Int
    public let size: Int

    public init(
        striking: Int, power: Int, kicking: Int, wrestling: Int, groundGame: Int,
        speed: Int, chin: Int, cardio: Int, fightIQ: Int, size: Int
    ) {
        func clamp(_ value: Int) -> Int { min(max(value, 0), 100) }
        self.striking = clamp(striking)
        self.power = clamp(power)
        self.kicking = clamp(kicking)
        self.wrestling = clamp(wrestling)
        self.groundGame = clamp(groundGame)
        self.speed = clamp(speed)
        self.chin = clamp(chin)
        self.cardio = clamp(cardio)
        self.fightIQ = clamp(fightIQ)
        self.size = clamp(size)
    }

    public subscript(attribute: FighterAttribute) -> Int {
        switch attribute {
        case .striking: return striking
        case .power: return power
        case .kicking: return kicking
        case .wrestling: return wrestling
        case .groundGame: return groundGame
        case .speed: return speed
        case .chin: return chin
        case .cardio: return cardio
        case .fightIQ: return fightIQ
        case .size: return size
        }
    }

    public func tier(for attribute: FighterAttribute) -> Tier {
        Tier(score: self[attribute])
    }

    public var values: [FighterAttribute: Int] {
        Dictionary(uniqueKeysWithValues: FighterAttribute.allCases.map { ($0, self[$0]) })
    }
}

public struct FighterRecord: Sendable, Hashable, Codable {
    public let wins: Int
    public let losses: Int
    public let draws: Int
    public let noContests: Int

    public init(wins: Int, losses: Int, draws: Int = 0, noContests: Int = 0) {
        self.wins = wins
        self.losses = losses
        self.draws = draws
        self.noContests = noContests
    }

    /// "30-4-1" or "28-1 (1 NC)".
    public var display: String {
        var text = "\(wins)-\(losses)"
        if draws > 0 { text += "-\(draws)" }
        if noContests > 0 { text += " (\(noContests) NC)" }
        return text
    }
}

public struct Nationality: Sendable, Hashable, Codable {
    public let name: String
    /// ISO 3166-1 alpha-2, e.g. "US".
    public let isoCode: String

    public init(name: String, isoCode: String) {
        self.name = name
        self.isoCode = isoCode.uppercased()
    }

    public var flagEmoji: String {
        let scalars = isoCode.unicodeScalars.compactMap { UnicodeScalar(127_397 + $0.value) }
        return String(String.UnicodeScalarView(scalars))
    }
}

public struct Fighter: Identifiable, Sendable, Hashable, Codable {
    public let id: String
    public let name: String
    public let nickname: String?
    public let nationality: Nationality
    public let weightClass: WeightClass
    public let record: FighterRecord
    public let attributes: FighterAttributes

    public init(
        id: String, name: String, nickname: String?, nationality: Nationality,
        weightClass: WeightClass, record: FighterRecord, attributes: FighterAttributes
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.nationality = nationality
        self.weightClass = weightClass
        self.record = record
        self.attributes = attributes
    }

    public var initials: String {
        name.split(separator: " ").compactMap(\.first).prefix(2).map(String.init).joined().uppercased()
    }

    /// "Anderson Silva" → "Silva", "Georges St-Pierre" → "St-Pierre".
    public var lastName: String {
        name.split(separator: " ").last.map(String.init) ?? name
    }
}
