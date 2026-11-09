import Foundation
import GoatDomain

/// Phase 1 repository backed by the bundled sample catalog.
/// Phase 2 replaces this with a SwiftData-backed store behind the same protocol.
public struct InMemoryFighterRepository: FighterRepository {
    private let fighters: [Fighter]

    public init(fighters: [Fighter] = SampleFighterCatalog.fighters) {
        self.fighters = fighters
    }

    public func allFighters() throws -> [Fighter] {
        fighters
    }
}
