// swift-tools-version: 6.0
import PackageDescription

/// BuildAGoatKit — all game code lives here, split into three layers:
///
///   GoatDomain        Pure Swift. Models, rules, rating math, seeded RNG, game engine.
///                     No SwiftUI / UIKit imports — fully unit-testable on any platform.
///   GoatData          Fighter catalog + repository implementations (SwiftData in Phase 2).
///   GoatPresentation  SwiftUI design system, screens and @Observable view models.
///                     Depends on GoatDomain only; the app target is the composition root.
let package = Package(
    name: "BuildAGoatKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "GoatDomain", targets: ["GoatDomain"]),
        .library(name: "GoatData", targets: ["GoatData"]),
        .library(name: "GoatPresentation", targets: ["GoatPresentation"]),
    ],
    targets: [
        .target(name: "GoatDomain"),
        .target(name: "GoatData", dependencies: ["GoatDomain"]),
        .target(name: "GoatPresentation", dependencies: ["GoatDomain"]),
        .testTarget(name: "GoatDomainTests", dependencies: ["GoatDomain", "GoatData"]),
    ],
    swiftLanguageModes: [.v6]
)
