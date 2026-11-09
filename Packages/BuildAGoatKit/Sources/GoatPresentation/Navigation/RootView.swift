import SwiftUI
import GoatDomain

enum AppRoute: Hashable {
    case builder
    case buildSummary
}

/// Pre-built app states used to capture README screenshots in CI
/// (launch with `-demoScene <name>`). Every scene uses a fixed seed.
public enum DemoScene: String, CaseIterable, Sendable {
    case home
    case builder
    case drafting
    case switching
    case complete
    case summary

    static let seed: UInt64 = 2026
}

/// App shell: Home → Fighter Builder → Build summary (career sim in Phase 3).
/// Receives its dependencies from the app target (composition root).
public struct RootView: View {
    private let fighters: [Fighter]
    private let loadError: String?

    @State private var path: [AppRoute]
    @State private var builder: FighterBuilderViewModel?

    public init(repository: any FighterRepository, demoScene: DemoScene? = nil) {
        var fighters: [Fighter] = []
        var loadError: String?
        do {
            fighters = try repository.allFighters()
            if fighters.isEmpty { loadError = "The fighter roster is empty." }
        } catch {
            loadError = error.localizedDescription
        }
        self.fighters = fighters
        self.loadError = loadError

        let demo = loadError == nil ? Self.makeDemo(demoScene, fighters: fighters) : nil
        _path = State(initialValue: demo?.path ?? [])
        _builder = State(initialValue: demo?.builder)
    }

    public var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let loadError {
                    ContentUnavailableView("Couldn't load fighters", systemImage: "exclamationmark.triangle", description: Text(loadError))
                } else {
                    HomeView(
                        continueProgress: continueProgress,
                        rosterCount: fighters.count,
                        onNewGame: startNewGame,
                        onContinue: { path = [.builder] }
                    )
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                destination(route)
            }
        }
        .tint(GoatTheme.accent)
        .preferredColorScheme(.dark)
    }

    /// Offer "continue" for an unfinished game that has at least one spin.
    private var continueProgress: Int? {
        guard let builder, builder.spinCount > 0, !builder.isComplete else { return nil }
        return builder.filledCount
    }

    private func startNewGame() {
        builder = try? FighterBuilderViewModel(fighters: fighters)
        path = [.builder]
    }

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
        case .builder:
            if let builder {
                FighterBuilderView(viewModel: builder, onSimulate: { path.append(.buildSummary) })
            }
        case .buildSummary:
            if let builder {
                BuildSummaryView(session: builder.session, rating: builder.overallRating)
            }
        }
    }

    @MainActor
    private static func makeDemo(_ scene: DemoScene?, fighters: [Fighter]) -> (path: [AppRoute], builder: FighterBuilderViewModel)? {
        guard let scene, scene != .home,
              let builder = try? FighterBuilderViewModel(fighters: fighters, seed: DemoScene.seed)
        else { return nil }

        switch scene {
        case .home:
            return nil
        case .builder:
            return ([.builder], builder)
        case .drafting:
            builder.prepareDemo(lockedPicks: 4, revealNextSpin: true)
            return ([.builder], builder)
        case .switching:
            builder.prepareDemo(lockedPicks: 4, revealNextSpin: true, pickOnRevealed: true)
            return ([.builder], builder)
        case .complete:
            builder.prepareDemo(lockedPicks: GameSession.totalSlots)
            return ([.builder], builder)
        case .summary:
            builder.prepareDemo(lockedPicks: GameSession.totalSlots)
            return ([.builder, .buildSummary], builder)
        }
    }
}
