import Testing
import GoatDomain
import GoatData

// MARK: - Tiers

@Suite("Tier mapping")
struct TierTests {
    @Test(arguments: [
        (100, Tier.s), (97, .s), (96, .aPlus), (93, .aPlus), (92, .a), (89, .a),
        (88, .aMinus), (85, .aMinus), (84, .bPlus), (81, .bPlus), (80, .b), (77, .b),
        (76, .bMinus), (73, .bMinus), (72, .cPlus), (69, .cPlus), (68, .c), (65, .c),
        (64, .cMinus), (60, .cMinus), (59, .d), (0, .d),
    ])
    func boundaries(score: Int, expected: Tier) {
        #expect(Tier(score: score) == expected)
    }

    @Test func clampsOutOfRange() {
        #expect(Tier(score: 140) == .s)
        #expect(Tier(score: -5) == .d)
    }

    @Test func roundsDoubles() {
        #expect(Tier(score: 96.6) == .s)
        #expect(Tier(score: 96.4) == .aPlus)
    }

    @Test func rangesCoverZeroToHundredWithoutGaps() {
        let covered = Tier.allCases.flatMap { Array($0.scoreRange) }.sorted()
        #expect(covered == Array(0...100))
    }

    @Test func ordering() {
        #expect(Tier.s > .aPlus)
        #expect(Tier.cMinus > .d)
    }
}

// MARK: - Weights & overall rating

@Suite("Overall rating")
struct OverallRatingTests {
    @Test func standardWeightsSumToOne() {
        #expect(abs(AttributeWeights.standard.total - 1.0) < 0.0001)
    }

    @Test func rejectsInvalidWeights() {
        var weights = Dictionary(uniqueKeysWithValues: FighterAttribute.allCases.map { ($0, 0.1) })
        #expect(throws: Never.self) { try AttributeWeights(weights) }

        weights[.size] = 0.2
        #expect(throws: AttributeWeights.ValidationError.self) { try AttributeWeights(weights) }

        weights.removeValue(forKey: .size)
        #expect(throws: AttributeWeights.ValidationError.missing(.size)) { try AttributeWeights(weights) }
    }

    @Test func uniformValuesWithoutHolesRateExactly() throws {
        let values = Dictionary(uniqueKeysWithValues: FighterAttribute.allCases.map { ($0, 90) })
        let rating = try #require(OverallRatingCalculator().rating(for: values))
        #expect(abs(rating.score - 90) < 0.0001)
        #expect(rating.tier == .a)
        #expect(rating.isProvisional == false)
    }

    @Test func isWeightedNotAPlainAverage() throws {
        // High in heavily-weighted wrestling, low in lightly-weighted kicking.
        var values = Dictionary(uniqueKeysWithValues: FighterAttribute.allCases.map { ($0, 80) })
        values[.wrestling] = 100
        values[.kicking] = 72
        let plainAverage = Double(values.values.reduce(0, +)) / Double(values.count)
        let rating = try #require(OverallRatingCalculator().rating(for: values))
        #expect(rating.score > plainAverage)
    }

    @Test func weaknessesArePenalised() throws {
        let calculator = OverallRatingCalculator()
        var solid = Dictionary(uniqueKeysWithValues: FighterAttribute.allCases.map { ($0, 85) })
        let baseline = try #require(calculator.rating(for: solid)).score

        solid[.chin] = 50
        let withHole = try #require(calculator.rating(for: solid)).score
        let pureMeanDrop = 35 * AttributeWeights.standard[.chin]
        #expect(baseline - withHole > pureMeanDrop)
    }

    @Test func partialBuildIsProvisional() throws {
        let rating = try #require(OverallRatingCalculator().rating(for: [.striking: 95]))
        #expect(rating.isProvisional)
        #expect(rating.displayScore == 95)
        #expect(OverallRatingCalculator().rating(for: [:]) == nil)
    }
}

// MARK: - Random selection

@Suite("Fighter selection engine")
struct SelectionEngineTests {
    let roster = SampleFighterCatalog.fighters

    @Test func sameSeedSameSequence() throws {
        var a = try FighterSelectionEngine(fighters: roster, seed: 42)
        var b = try FighterSelectionEngine(fighters: roster.shuffled(), seed: 42)
        for _ in 0..<50 {
            #expect(a.next().fighter.id == b.next().fighter.id)
        }
    }

    @Test func differentSeedsDiverge() throws {
        var a = try FighterSelectionEngine(fighters: roster, seed: 1)
        var b = try FighterSelectionEngine(fighters: roster, seed: 2)
        let first = (0..<20).map { _ in a.next().fighter.id }
        let second = (0..<20).map { _ in b.next().fighter.id }
        #expect(first != second)
    }

    @Test func fighterAlwaysBelongsToDrawnDivision() throws {
        var engine = try FighterSelectionEngine(fighters: roster, seed: 7)
        for _ in 0..<500 {
            let draw = engine.next()
            #expect(draw.fighter.weightClass == draw.weightClass)
        }
    }

    @Test func everyDivisionEventuallyAppears() throws {
        var engine = try FighterSelectionEngine(fighters: roster, seed: 99)
        let seen = Set((0..<2_000).map { _ in engine.next().weightClass })
        #expect(seen == Set(WeightClass.allCases))
    }

    @Test func emptyRosterThrows() {
        #expect(throws: GameError.noFighters) { try FighterSelectionEngine(fighters: [], seed: 1) }
    }
}

// MARK: - Game rules

@Suite("Game engine rules")
struct GameEngineTests {
    let roster = SampleFighterCatalog.fighters

    @Test func cannotSelectBeforeSpinning() throws {
        var engine = try GameEngine(fighters: roster, seed: 3)
        #expect(throws: GameError.noActiveSpin) { try engine.select(.striking) }
    }

    @Test func mustPickBeforeSpinningAgain() throws {
        var engine = try GameEngine(fighters: roster, seed: 3)
        try engine.spin()
        #expect(engine.phase == .awaitingSelection)
        #expect(throws: GameError.selectionPending) { try engine.spin() }
    }

    @Test func pickCanBeSwitchedUntilNextSpin() throws {
        var engine = try GameEngine(fighters: roster, seed: 3)
        let spin = try engine.spin()
        try engine.select(.cardio)
        let switched = try engine.select(.power)

        // Still exactly one attribute from this spin, and the old slot is free again.
        #expect(engine.session.filledCount == 1)
        #expect(engine.session.isFilled(.cardio) == false)
        #expect(switched.attribute == .power)
        #expect(switched.sourceFighterID == spin.fighter.id)
        #expect(engine.session.currentSpin?.selectedAttribute == .power)
        #expect(engine.canSelect(.cardio))
    }

    @Test func reselectingSamePickIsNoOp() throws {
        var engine = try GameEngine(fighters: roster, seed: 3)
        try engine.spin()
        let first = try engine.select(.chin)
        #expect(try engine.select(.chin) == first)
        #expect(engine.session.filledCount == 1)
    }

    @Test func spinningLocksThePick() throws {
        var engine = try GameEngine(fighters: roster, seed: 3)
        try engine.spin()
        try engine.select(.speed)
        #expect(engine.isLocked(.speed) == false)
        try engine.spin()
        #expect(engine.isLocked(.speed))
        #expect(throws: GameError.slotAlreadyFilled(.speed)) { try engine.select(.speed) }
    }

    @Test func lastPickCanStillBeSwitched() throws {
        var engine = try GameEngine(fighters: roster, seed: 8)
        let attributes = FighterAttribute.allCases
        for attribute in attributes.dropLast(2) {
            try engine.spin()
            try engine.select(attribute)
        }
        try engine.spin()
        try engine.select(attributes[attributes.count - 2])
        try engine.spin()
        try engine.select(attributes[attributes.count - 1])
        #expect(engine.session.isComplete)
        // Ninth slot is locked; the tenth pick can't move onto it.
        #expect(throws: GameError.slotAlreadyFilled(attributes[attributes.count - 2])) {
            try engine.select(attributes[attributes.count - 2])
        }
    }

    @Test func filledSlotIsPermanent() throws {
        var engine = try GameEngine(fighters: roster, seed: 3)
        try engine.spin()
        let first = try engine.select(.fightIQ)
        try engine.spin()
        #expect(throws: GameError.slotAlreadyFilled(.fightIQ)) { try engine.select(.fightIQ) }
        #expect(engine.session.selection(for: .fightIQ) == first)
        #expect(engine.canSelect(.fightIQ) == false)
    }

    @Test func selectionRecordsSourceFighter() throws {
        var engine = try GameEngine(fighters: roster, seed: 11)
        let spin = try engine.spin()
        let selection = try engine.select(.wrestling)
        #expect(selection.sourceFighterID == spin.fighter.id)
        #expect(selection.sourceFighterName == spin.fighter.name)
        #expect(selection.numericalValue == spin.fighter.attributes.wrestling)
        #expect(selection.tier == Tier(score: spin.fighter.attributes.wrestling))
        #expect(selection.spinNumber == 1)
        #expect(engine.session.currentSpin?.selectedAttribute == .wrestling)
    }

    @Test func customDivisionComesFromSizePick() throws {
        var engine = try GameEngine(fighters: roster, seed: 5)
        #expect(engine.session.weightClass == nil)
        let spin = try engine.spin()
        try engine.select(.size)
        #expect(engine.session.weightClass == spin.fighter.weightClass)
    }

    @Test(arguments: [UInt64(1), 2, 3, 42, 2_026, 99_999])
    func fullGameCompletesInTenSpins(seed: UInt64) throws {
        var engine = try GameEngine(fighters: roster, seed: seed)
        for attribute in FighterAttribute.allCases {
            try engine.spin()
            try engine.select(attribute)
        }
        #expect(engine.session.isComplete)
        #expect(engine.phase == .complete)
        #expect(engine.session.spinCount == 10)
        #expect(engine.overallRating?.isProvisional == false)
        #expect(throws: GameError.gameComplete) { try engine.spin() }
    }

    @Test func sameSeedReplaysIdenticalGame() throws {
        func play(_ seed: UInt64) throws -> [String] {
            var engine = try GameEngine(fighters: roster, seed: seed)
            return try FighterAttribute.allCases.map { attribute in
                try engine.spin()
                return try engine.select(attribute).sourceFighterID
            }
        }
        #expect(try play(2_026) == play(2_026))
    }
}

// MARK: - Dataset integrity

@Suite("Sample catalog")
struct CatalogTests {
    let roster = SampleFighterCatalog.fighters

    @Test func idsAreUnique() {
        #expect(Set(roster.map(\.id)).count == roster.count)
    }

    @Test func everyDivisionIsCovered() {
        #expect(Set(roster.map(\.weightClass)) == Set(WeightClass.allCases))
    }

    @Test func ratingsAreInRange() {
        for fighter in roster {
            for attribute in FighterAttribute.allCases {
                #expect((0...100).contains(fighter.attributes[attribute]), "\(fighter.id) \(attribute)")
            }
        }
    }

    @Test func repositoryReturnsCatalog() throws {
        #expect(try InMemoryFighterRepository().allFighters().count == roster.count)
    }
}
