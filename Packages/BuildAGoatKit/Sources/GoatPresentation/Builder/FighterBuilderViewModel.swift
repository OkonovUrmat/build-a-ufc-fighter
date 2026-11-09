import Foundation
import Observation
import GoatDomain

/// One attribute row of the fighter currently on screen.
public struct AttributeOption: Identifiable, Equatable, Sendable {
    public enum State: Equatable, Sendable {
        /// Can be taken right now (no pick yet on this spin).
        case available
        /// Picked from this fighter on this spin — still changeable until the next spin.
        case chosen
        /// Free slot; tapping moves this spin's pick here.
        case switchable
        /// Slot locked in on an earlier spin (by `sourceName`).
        case alreadyFilled(sourceName: String)
    }

    public let attribute: FighterAttribute
    public let value: Int
    public let tier: Tier
    public let state: State

    public var id: FighterAttribute { attribute }
    public var isSelectable: Bool { state == .available || state == .switchable }
}

/// Cosmetic frame shown while the reel spins.
public struct ReelFrame: Equatable, Sendable {
    public let fighterName: String
    public let weightClass: WeightClass
}

public struct SelectionToast: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let selection: AttributeSelection
    /// Set when the pick was moved from another slot on the same spin.
    public let switchedFrom: FighterAttribute?
}

@MainActor
@Observable
public final class FighterBuilderViewModel {
    public private(set) var engine: GameEngine
    public private(set) var isSpinning = false
    public private(set) var reelFrame: ReelFrame?
    /// Increments each reel tick — drives haptics and the reel transition.
    public private(set) var reelTick = 0
    /// Increments when a spun fighter is revealed.
    public private(set) var revealCount = 0
    public private(set) var toast: SelectionToast?
    /// Increments on every pick or switch — drives haptics.
    public private(set) var selectionTick = 0

    private let fighters: [Fighter]
    @ObservationIgnored private var spinTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?

    public init(fighters: [Fighter], seed: UInt64 = UInt64.random(in: UInt64.min...UInt64.max)) throws {
        self.fighters = fighters
        self.engine = try GameEngine(fighters: fighters, seed: seed)
    }

    // MARK: Read model

    public var session: GameSession { engine.session }
    public var slots: [AttributeSlot] { session.slots }
    public var filledCount: Int { session.filledCount }
    public var remainingCount: Int { session.remainingCount }
    public var spinCount: Int { session.spinCount }
    public var isComplete: Bool { session.isComplete }
    public var overallRating: OverallRating? { engine.overallRating }
    public var customWeightClass: WeightClass? { session.weightClass }

    /// The revealed spin (hidden while the reel is still turning).
    public var currentSpin: SpinResult? {
        isSpinning ? nil : session.currentSpin
    }

    public var currentFighterRating: OverallRating? {
        currentSpin.map { engine.calculator.rating(for: $0.fighter.attributes) }
    }

    public var canSpin: Bool {
        !isSpinning && session.phase == .readyToSpin
    }

    public var options: [AttributeOption] {
        guard let spin = currentSpin else { return [] }
        return FighterAttribute.allCases.map { attribute in
            let value = spin.fighter.attributes[attribute]
            let state: AttributeOption.State
            if spin.selectedAttribute == attribute {
                state = .chosen
            } else if engine.isLocked(attribute), let existing = session.selection(for: attribute) {
                state = .alreadyFilled(sourceName: existing.sourceFighterName)
            } else if spin.selectedAttribute != nil {
                state = .switchable
            } else {
                state = .available
            }
            return AttributeOption(attribute: attribute, value: value, tier: Tier(score: value), state: state)
        }
    }

    public var spinButtonTitle: String {
        if isSpinning { return "SPINNING" }
        switch session.phase {
        case .complete: return "SIMULATE CAREER"
        case .awaitingSelection: return "PICK AN ATTRIBUTE"
        case .readyToSpin: return spinCount == 0 ? "SPIN" : "LOCK IN & SPIN"
        }
    }

    public var statusMessage: String {
        if isSpinning { return "Drawing a random division and fighter…" }
        switch session.phase {
        case .complete:
            return "Build complete. You can still switch your last pick before simulating."
        case .awaitingSelection:
            let name = session.currentSpin?.fighter.lastName ?? "this fighter"
            return "Take ONE attribute from \(name). It's locked in for the rest of the game."
        case .readyToSpin:
            if spinCount == 0 { return "Spin to draw your first legend." }
            let picked = session.pendingSelection?.attribute.displayName ?? "Your pick"
            return "\(picked) added. Tap another free attribute to switch, or spin to lock it in."
        }
    }

    // MARK: Intents

    public func spin(reduceMotion: Bool = false) {
        guard canSpin else { return }
        do {
            try engine.spin()
        } catch {
            return
        }
        isSpinning = true
        spinTask?.cancel()

        let frameCount = reduceMotion ? 2 : 12
        spinTask = Task { [weak self] in
            for index in 0..<frameCount {
                guard let self, !Task.isCancelled else { return }
                self.reelFrame = self.makeReelFrame()
                self.reelTick &+= 1
                // Ease out: ticks get slower like a wheel losing speed.
                try? await Task.sleep(for: .milliseconds(35 + index * index * 2))
            }
            guard let self else { return }
            self.reelFrame = nil
            self.isSpinning = false
            self.revealCount &+= 1
        }
    }

    public func select(_ attribute: FighterAttribute) {
        guard !isSpinning else { return }
        do {
            let previous = session.pendingSelection?.attribute
            let selection = try engine.select(attribute)
            guard previous != selection.attribute else { return }
            selectionTick &+= 1
            showToast(for: selection, switchedFrom: previous)
        } catch {
            // Invalid taps are prevented by the UI; nothing to surface.
        }
    }

    public func newGame() {
        spinTask?.cancel()
        toastTask?.cancel()
        isSpinning = false
        reelFrame = nil
        toast = nil
        if let fresh = try? GameEngine(fighters: fighters, seed: UInt64.random(in: UInt64.min...UInt64.max)) {
            engine = fresh
        }
    }

    // MARK: Demo

    /// Deterministic auto-play for screenshots and previews: locks in `lockedPicks`
    /// spins (taking each fighter's best free attribute), then optionally reveals
    /// one more fighter and/or makes a pending pick on it.
    func prepareDemo(lockedPicks: Int, revealNextSpin: Bool = false, pickOnRevealed: Bool = false) {
        for _ in 0..<lockedPicks {
            guard (try? engine.spin()) != nil else { return }
            pickBestFreeAttribute()
        }
        guard revealNextSpin, (try? engine.spin()) != nil else { return }
        if pickOnRevealed { pickBestFreeAttribute() }
    }

    private func pickBestFreeAttribute() {
        guard let fighter = session.currentSpin?.fighter else { return }
        let best = FighterAttribute.allCases
            .filter { !session.isFilled($0) }
            .max { fighter.attributes[$0] < fighter.attributes[$1] }
        if let best { _ = try? engine.select(best) }
    }

    // MARK: Private

    private func makeReelFrame() -> ReelFrame {
        let fighter = fighters.randomElement()
        return ReelFrame(
            fighterName: fighter?.name ?? "—",
            weightClass: fighter?.weightClass ?? .lightweight
        )
    }

    private func showToast(for selection: AttributeSelection, switchedFrom previous: FighterAttribute?) {
        let toast = SelectionToast(selection: selection, switchedFrom: previous)
        self.toast = toast
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.8))
            guard let self, !Task.isCancelled, self.toast?.id == toast.id else { return }
            self.toast = nil
        }
    }
}
