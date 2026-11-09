import SwiftUI
import GoatData
import GoatPresentation

/// Composition root: wires the Data layer into the Presentation layer.
@main
struct BuildAGoatApp: App {
    private let repository = InMemoryFighterRepository()

    /// `-demoScene drafting` (launch argument) opens a deterministic pre-built state.
    /// Used by CI to capture README screenshots.
    private let demoScene = UserDefaults.standard.string(forKey: "demoScene").flatMap(DemoScene.init(rawValue:))

    var body: some Scene {
        WindowGroup {
            RootView(repository: repository, demoScene: demoScene)
        }
    }
}
