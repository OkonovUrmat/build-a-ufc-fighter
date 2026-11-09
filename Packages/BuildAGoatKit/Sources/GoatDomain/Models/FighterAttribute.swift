import Foundation

/// The ten draftable attribute slots of a custom fighter.
///
/// To add REACH (optional in the spec) add a case here, a property in
/// `FighterAttributes`, a weight in `AttributeWeights.standard`
/// and an anchor in the presentation layer's board layout.
public enum FighterAttribute: String, CaseIterable, Sendable, Codable, Hashable, Identifiable {
    case striking
    case power
    case kicking
    case wrestling
    case groundGame
    case speed
    case chin
    case cardio
    case fightIQ
    case size

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .striking: return "STRIKING"
        case .power: return "POWER"
        case .kicking: return "KICKING"
        case .wrestling: return "WRESTLING"
        case .groundGame: return "GROUND GAME"
        case .speed: return "SPEED"
        case .chin: return "CHIN"
        case .cardio: return "CARDIO"
        case .fightIQ: return "FIGHT IQ"
        case .size: return "SIZE"
        }
    }

    public var summary: String {
        switch self {
        case .striking: return "Boxing technique, volume and accuracy"
        case .power: return "One-shot finishing power"
        case .kicking: return "Kicks, knees and leg attacks"
        case .wrestling: return "Takedowns, takedown defence, control"
        case .groundGame: return "Jiu-jitsu, submissions, ground strikes"
        case .speed: return "Hand speed, footwork, reactions"
        case .chin: return "Durability and recovery"
        case .cardio: return "Five-round gas tank and pace"
        case .fightIQ: return "Reads, adjustments, game planning"
        case .size: return "Frame, reach and strength for the division"
        }
    }
}
