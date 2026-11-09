import Foundation

/// Source of historical fighters. The domain only knows this protocol;
/// GoatData provides the implementation (in-memory now, SwiftData-backed in Phase 2).
public protocol FighterRepository: Sendable {
    func allFighters() throws -> [Fighter]
}
