<h1 align="center">MacAssed</h1>
<p align="center"><strong>Putting the Mac back in SwiftUI.</strong></p>
<p align="center"><em>MacAssed is an attempt to recover some of the functionality that modern<br>minimalist interfaces have misplaced. Welcome to the Lost&nbsp;&amp;&nbsp;Found.</em></p>

---

> **Status: design sketch (pre-alpha).** This repository is the *design* of the
> library — a settled API shape with illustrative, not-yet-implemented bodies.
> It intentionally doesn’t build yet (no `import`-and-ship), and the SwiftUI
> layer is Apple-only besides. What’s real and runnable is the plan, the API
> surface in `Sources/`, and the `MacAssedCore` behavior described by the tests.

## The problem

SwiftUI made shipping an app so frictionless that the easy path now leads
somewhere austere: a list you can’t sort, can’t properly multi-select, can’t
type-select, that forgets its columns the moment you quit. The affordances
desktop users have relied on for thirty years didn’t get *rejected* — they got
*skipped*, because reaching for them stopped being the default.

John Gruber put the specific case plainly in August 2026, on TestFlight’s
un-sortable build list:

> *”You can still do this in Mac-assed Mac apps. But in apps like TestFlight you
> can’t.”* — [Daring Fireball](https://daringfireball.net/2026/08/apple_testflight_list_sort_order)

**MacAssed** reimplements those table-stakes affordances on top of SwiftUI, as a
foundation of stable, sensible defaults — so an app built The Swift Way can be a
Mac-assed app again.

## The 30-second version

```swift
// Before — an austere SwiftUI list.
List(files, selection: $selection) { Text($0.name) }

// After — Finder-style sort, ⇧/⌘/marquee selection, type-select,
// keyboard nav, column resize/reorder/hide, and autosave. All on by default.
MATable(files, selection: $selection) {
    MAColumn("Name", value: \.name)
    MAColumn("Size", value: \.size, align: .trailing)
}
.columnAutosave("Files")
```

Batteries included: you opt *out* of affordances, not in.

## The three drawers

| | |
|---|---|
| **[Lost&nbsp;&amp;&nbsp;Found](docs/Lost-and-Found.md)** | The catalog — every misplaced affordance, tagged 🔦 *gone* or 🥾 *needs a Swift kick*. |
| **[Tools](docs/Tools.md)** | Things MacAssed gives you to put them back — `MATable`, `MASort`, `MASelection`, … |
| **[Examples](docs/Examples.md)** | Evidence that this was, in fact, possible. |

Engineering details — the two-module architecture, platform matrix, roadmap, and
what this is *not* (SwiftUIX, the “mac-arsed” skill) — live in
**[DESIGN.md](DESIGN.md)**.

## Install

```swift
// Package.swift
.package(url: "https://github.com/kimslawson/mac-assed.git", branch: "main")
```

```swift
import MacAssed        // views, modifiers, commands, chrome
import MacAssedCore    // just the UI-free engine, if you want the behavior not our views
```

Requires macOS 14 / iOS 17 / visionOS 1 for the SwiftUI layer. `MacAssedCore`
builds anywhere Swift does, Linux CI included.

## On the name

A *”Mac-assed Mac app”* is a running term of art among Mac developers — an app
that wholeheartedly embraces the platform instead of settling for a
lowest-common-denominator port. Coined by Collin Donnell, popularized by Brent
Simmons, and used [recurrently by Gruber since
2020](https://daringfireball.net/linked/2020/03/20/mac-assed-mac-apps). We put
the link in the README so the homage is self-sourcing.

And the **`MA` prefix** is a small joke that means it. Old Apple frameworks
prefixed types — `NS`, `UI`, `CG`, `MK` — because Objective-C had no namespaces.
Swift made that “unnecessary,” and the prefixes vanished in the *same* cultural
moment the UI conventions did. So MacAssed brings the prefix back: `MATable`,
`MASortDescriptor`, `MASelection`. The branding does the thing the library does
— recovers a good convention that got dropped for looking old-fashioned. (The
*module* is `MacAssed`; the *types* are `MA…` — exactly `Foundation`’s
relationship to its `NS…` types.)

## Naming conventions

Swift casing splits names into **types** (nouns) and **members** (the things you
do to them). The `MA` prefix follows along — uppercase on a type, lowercase on a
method. The leading dot is call syntax (`view.padding()`), not part of the name.

| You write | What it is | Case rule |
|---|---|---|
| `MATable`, `MASort` | a **type** (a thing) | UpperCamelCase → prefix shows as `MA` |
| `.maTypeSelect(…)` | a **modifier** on Apple’s `View` | lowerCamelCase → `ma`; dot calls it on the view |
| `.columnAutosave(…)` | a **method on `MATable`** | lowerCamelCase, no prefix — the type already namespaces it |
| `.platinum`, `.trailing` | an **enum case** (a fixed option) | lowerCamelCase; dot = the option, on the inferred type |

Same grammar Apple uses: `NSString` / `UIView` are Upper with the prefix; their
members (`view.backgroundColor`) are lower.

## Contributing

The catalog is meant to grow with the community — a foundation that lives and
flexes with Swift. Missing an affordance, or want to claim a roadmap item? See
**[CONTRIBUTING.md](CONTRIBUTING.md)**.

## License

MIT (intended) — see [LICENSE](LICENSE).
