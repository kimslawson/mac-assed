// swift-tools-version: 6.0
//
//  MacAssed — put proper mac-assed functionality back into SwiftUI apps.
//
//  This manifest establishes the module layering described in DESIGN.md:
//
//      MacAssedCore   — Foundation-only. Sorting, selection, column layout,
//                       and view-state persistence. No SwiftUI, no AppKit.
//                       Unit-testable on any platform, including Linux CI.
//
//      MacAssed       — The SwiftUI layer. Views, view modifiers, commands,
//                       and opt-in classic chrome. Depends on Core.
//
//  NOTE: The `MacAssed` (SwiftUI) target compiles on Apple platforms only.
//  `MacAssedCore` is pure Swift/Foundation and builds anywhere, which is why
//  the split exists: the interesting logic can be tested without a simulator.
//
import PackageDescription

let package = Package(
    name: "MacAssed",
    // Baselines chosen for the affordances we lean on:
    //   .onKeyPress (type-select), Table column customization, @Observable,
    //   and Swift 6 strict concurrency. Older OSes get graceful fallbacks.
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .visionOS(.v1),
        .macCatalyst(.v17),
    ],
    products: [
        // The batteries-included umbrella most apps will import.
        .library(name: "MacAssed", targets: ["MacAssed"]),
        // The UI-free engine, for teams who want the behavior without our views.
        .library(name: "MacAssedCore", targets: ["MacAssedCore"]),
    ],
    targets: [
        .target(
            name: "MacAssedCore"
        ),
        .target(
            name: "MacAssed",
            dependencies: ["MacAssedCore"]
        ),
        .testTarget(
            name: "MacAssedCoreTests",
            dependencies: ["MacAssedCore"]
        ),
    ]
)
