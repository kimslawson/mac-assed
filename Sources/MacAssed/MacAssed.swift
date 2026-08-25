//
//  MacAssed.swift  ·  MacAssed
//
//  ███  MacAssed — putting the Mac back in SwiftUI.  ███
//
//  MacAssed is an attempt to recover some of the functionality that modern
//  minimalist interfaces have misplaced. Welcome to the Lost & Found.
//
//  ── On the name ──────────────────────────────────────────────────────────
//  A "Mac-assed Mac app" is a running term of art among Mac developers — an app
//  that wholeheartedly embraces the platform's conventions instead of settling
//  for a lowest-common-denominator port. Coined by Collin Donnell, popularized
//  by Brent Simmons, and used recurrently by John Gruber since 2020 (he calls
//  Safari "one of the best Mac apps, period" for embodying it). It surfaced
//  again in the 2026 TestFlight-sort-order piece that kicked this project off:
//
//      "You can still do this in Mac-assed Mac apps. But in apps like
//       TestFlight you can't."   — Daring Fireball, Aug 2026
//
//  ── On the MA prefix (a small joke that means it) ────────────────────────
//  Old Apple frameworks prefixed types with two/three letters — NS, UI, CG, AV,
//  MK — because Objective-C had no namespaces. Swift's module namespacing made
//  that "unnecessary," and the prefixes went away in the same cultural moment
//  the UI conventions did. So MacAssed brings the prefix back: `MATable`,
//  `MASortDescriptor`, `MASelection`. The branding does the thing the library
//  does — recovers a good convention that got dropped for looking old-fashioned.
//
//  The *module* is `MacAssed`; the *types* are `MA…` — exactly the relationship
//  `Foundation` has with its `NS…` types.
//
//  ── Layout ───────────────────────────────────────────────────────────────
//    import MacAssed        → views, modifiers, commands, chrome (this module)
//    import MacAssedCore    → the UI-free engine (sorting, selection, columns,
//                             view-state) if you want the behavior, not our views
//
//  See DESIGN.md for the architecture and docs/ for Lost & Found · Tools ·
//  Examples.
//

import Foundation

public enum MacAssed {
    /// Semantic version of the library.
    public static let version = "0.0.0-sketch"

    /// The etymology, one tap away — so the homage is self-sourcing.
    public static let etymology =
        URL(string: "https://daringfireball.net/2026/08/apple_testflight_list_sort_order")!
}
