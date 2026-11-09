import Foundation

public enum Gender: String, Sendable, Codable, Hashable {
    case men
    case women
}

/// Every UFC weight division, men's and women's.
public enum WeightClass: String, CaseIterable, Sendable, Codable, Hashable, Identifiable {
    case flyweight
    case bantamweight
    case featherweight
    case lightweight
    case welterweight
    case middleweight
    case lightHeavyweight
    case heavyweight
    case womensStrawweight
    case womensFlyweight
    case womensBantamweight
    case womensFeatherweight

    public var id: String { rawValue }

    public var gender: Gender {
        switch self {
        case .womensStrawweight, .womensFlyweight, .womensBantamweight, .womensFeatherweight:
            return .women
        default:
            return .men
        }
    }

    /// Division name without the gender prefix, e.g. "Flyweight".
    public var baseName: String {
        switch self {
        case .flyweight, .womensFlyweight: return "Flyweight"
        case .bantamweight, .womensBantamweight: return "Bantamweight"
        case .featherweight, .womensFeatherweight: return "Featherweight"
        case .lightweight: return "Lightweight"
        case .welterweight: return "Welterweight"
        case .middleweight: return "Middleweight"
        case .lightHeavyweight: return "Light Heavyweight"
        case .heavyweight: return "Heavyweight"
        case .womensStrawweight: return "Strawweight"
        }
    }

    /// Full display name, e.g. "Women's Flyweight".
    public var displayName: String {
        gender == .women ? "Women's \(baseName)" : baseName
    }

    /// Upper weight limit in pounds.
    public var limitPounds: Int {
        switch self {
        case .womensStrawweight: return 115
        case .flyweight, .womensFlyweight: return 125
        case .bantamweight, .womensBantamweight: return 135
        case .featherweight, .womensFeatherweight: return 145
        case .lightweight: return 155
        case .welterweight: return 170
        case .middleweight: return 185
        case .lightHeavyweight: return 205
        case .heavyweight: return 265
        }
    }
}
