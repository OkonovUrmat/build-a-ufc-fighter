import Foundation

/// Letter tier for a 0–100 rating.
///
/// S = 97–100, A+ = 93–96, A = 89–92, A- = 85–88, B+ = 81–84, B = 77–80,
/// B- = 73–76, C+ = 69–72, C = 65–68, C- = 60–64, D = 0–59.
public enum Tier: String, CaseIterable, Sendable, Codable, Hashable, Comparable {
    case s = "S"
    case aPlus = "A+"
    case a = "A"
    case aMinus = "A-"
    case bPlus = "B+"
    case b = "B"
    case bMinus = "B-"
    case cPlus = "C+"
    case c = "C"
    case cMinus = "C-"
    case d = "D"

    public var label: String { rawValue }

    /// Lowest score (inclusive) that earns this tier.
    public var minimumScore: Int {
        switch self {
        case .s: return 97
        case .aPlus: return 93
        case .a: return 89
        case .aMinus: return 85
        case .bPlus: return 81
        case .b: return 77
        case .bMinus: return 73
        case .cPlus: return 69
        case .c: return 65
        case .cMinus: return 60
        case .d: return 0
        }
    }

    public var scoreRange: ClosedRange<Int> {
        let all = Tier.allCases
        guard let index = all.firstIndex(of: self), index > 0 else { return minimumScore...100 }
        return minimumScore...(all[index - 1].minimumScore - 1)
    }

    public init(score: Int) {
        let clamped = min(max(score, 0), 100)
        // allCases is ordered best → worst, so the first match is the right tier.
        self = Tier.allCases.first { clamped >= $0.minimumScore } ?? .d
    }

    public init(score: Double) {
        self.init(score: Int(score.rounded()))
    }

    public static func < (lhs: Tier, rhs: Tier) -> Bool {
        lhs.minimumScore < rhs.minimumScore
    }
}
