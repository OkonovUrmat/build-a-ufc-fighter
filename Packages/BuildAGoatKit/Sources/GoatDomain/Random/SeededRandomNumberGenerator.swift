import Foundation

/// SplitMix64 — tiny, fast, and fully deterministic for a given seed.
/// Used for every game-affecting random decision so tests are reproducible.
public struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform index in `0..<count`. Implemented locally (instead of the
    /// standard library's `random(in:using:)`) so sequences stay identical
    /// across Swift toolchain versions.
    public mutating func nextIndex(below count: Int) -> Int {
        precondition(count > 0, "count must be positive")
        return Int(next() % UInt64(count))
    }

    /// Uniform Double in `0..<1`.
    public mutating func nextUnit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}
