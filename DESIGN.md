# MacAssed — Design

The engineering spine. What the pieces are, why they’re shaped this way, where
they run, and what order they get built in. For the *what-and-why-it-matters*,
start at [Lost & Found](docs/Lost-and-Found.md); for call sites, see
[Tools](docs/Tools.md) and [Examples](docs/Examples.md).

---

## Thesis

Modern minimalist interfaces have misplaced a lot of hard-won usability. SwiftUI
made building an app so frictionless that the path of least resistance now leads
to something austere — a `List` with no sort, no real multi-select, no
type-select, no memory. The affordances didn’t get *rejected*; they got *skipped*,
because reaching for them stopped being the default.

MacAssed’s bet: if the mac-assed affordances are the **easiest** thing to reach
for — one type name, sensible defaults, opt-out not opt-in — developers will use
them again, and a generation of apps gets its usability back.

## Design principles

1. **Opt-out, not opt-in.** The flagship controls ship with the full affordance
   set live. You remove what you don’t want. Defaults are the product.
2. **Native by default, nostalgic by choice.** Out of the box, MacAssed looks
   like a 2026 Mac app. Period skins ([`MAChrome`](docs/Tools.md#chrome--machrome-opt-in))
   are opt-in and never change *which* affordances exist — only their looks.
3. **Behavior is UI-free.** Sorting, selection, column, and view-state logic
   live in `MacAssedCore` — plain Swift, `Sendable`, `Codable`, tested on Linux.
   The SwiftUI layer is a thin translation of gestures to that core.
4. **Graft, don’t gut.** Every behavior is available as a standalone modifier so
   a team can adopt one thing without a rewrite.
5. **Persist by convention.** One `autosaveName` should bring a window back the
   way it was left — the AppKit contract, restored.
6. **Degrade honestly.** A multi-column table isn’t right on iPhone; MacAssed
   collapses to the correct simpler control rather than cramming.
7. **Accessibility is load-bearing, not a coat of paint.** Keyboard operability
   is what makes type-select and arrow-nav real; it ships with the affordance,
   not after it.
8. **Live with Swift, not against it.** Reuse `SortComparator`, `KeyPath`,
   `@Observable`, result builders. MacAssed should feel like the standard library
   the platform forgot to write, not a foreign framework.

## Architecture

Two modules, deliberately split — the same relationship `Foundation` (the
module) has with its `NS…` types:

```
┌──────────────────────────────────────────────────────────────┐
│  MacAssed        (SwiftUI · Apple platforms)                  │
│  MATable · MAList · MAColumn · MACommands · MAChrome ·        │
│  grafting modifiers · the AppKit bridge (NSTableView on mac)  │
└───────────────────────────────┬──────────────────────────────┘
                                 │ depends on
┌───────────────────────────────▼──────────────────────────────┐
│  MacAssedCore    (Foundation only · builds & tests anywhere)  │
│  MASort · MASortDescriptor · MAFinderComparator ·             │
│  MASelection · MAColumnLayout · MAViewState                   │
└──────────────────────────────────────────────────────────────┘
```

Why split:

- **Testability.** The interesting logic (natural-order sort, pivot-aware range
  selection, layout reconciliation) is verified without a simulator, on Linux
  CI, in milliseconds. See `Tests/MacAssedCoreTests`.
- **Reuse.** A team with its own design system can take the brains and skip our
  views entirely — `import MacAssedCore`.
- **Honesty about platforms.** SwiftUI is Apple-only; keeping it in one target
  makes the buildable-anywhere part obvious.

### The AppKit bridge

On macOS, `MATable`’s production implementation is backed by an `NSTableView`
via `NSViewRepresentable`, because AppKit already does pixel-true clickable
headers, live column resize, and type-select correctly and for free. On
iPad/iOS/visionOS it composes SwiftUI `Table`/`List`. The public API is
identical across both; the backing is an implementation detail behind a
`#if os(macOS)`.

## Persistence & autosave conventions

- One **autosave name** per window/scene. `MAViewState` namespaces everything
  under `MacAssed.<name>.<key>` so keys never collide and `defaults read` stays
  legible.
- State is **granular and optional** (`MAWindowState`): a list that only wants
  its sort remembered writes only that.
- Restored state is **reconciled** against the live declaration
  (`MAColumnLayout.reconcile(with:)`, `MASortState` re-hydrated by id) so app
  updates never corrupt a saved layout.
- Backing is **pluggable** (`MAViewStateStore`): `UserDefaults` today; SwiftData
  or iCloud key-value later, without touching call sites.

## Scope — Mac-first, platform-assed everywhere

MacAssed restores *desktop* affordances, and an affordance belongs to an input
model, not a logo. So the scope cuts the other way on iPhone: dragging Mac idioms
onto touch would make MacAssed the very thing it objects to. The rule is
**platform-assed** — Mac-assed on the Mac, iOS-assed on iOS.

- **macOS — flagship, first-class.** Where the affordances were lost and where
  they belong.
- **iPadOS — first-class *when* a pointer or hardware keyboard is present.** A
  docked iPad is a desktop-class machine and suffers the same austerity (Files,
  say). Gate the pointer/keyboard affordances on the *input*, not the OS.
- **iOS (iPhone) — deliberately minimal.** Only universal capabilities, in
  native dress; never Mac chrome; then get out of the way.

`MacAssedCore` (sorting, the selection model, layout) is platform-neutral and
useful anywhere; only the *presentation* is platform-specific. The brand is Mac
because that’s where the fight is — the discipline is symmetric.

### What crosses, and how

Three buckets sort every affordance:

- **Input-bound** — needs a pointer or a physical keyboard: marquee, hover
  tooltips, right-click, ⇧/⌘ ranges, type-select, arrow-nav. Present on Mac and
  on pointer/keyboard iPad; simply absent on touch (no hover, no modifiers, no
  keys). Gate by input capability.
- **Form-bound** — needs screen real estate or windows: multi-column tables,
  column resize/reorder/hide, spatial windows, floating inspectors. Mac and large
  iPad; on iPhone they collapse to a single-column list.
- **Idiom-bound** — the capability is universal but iOS already has a native
  expression, so translate the capability and render it natively:

  | Capability | Mac | iOS |
  |---|---|---|
  | Sort | clickable column headers | a “Sort” menu button (Files/Photos-style) |
  | Multi-select | ⇧/⌘-click | Edit mode + two-finger drag-select |
  | Find | ⌘F slide-down bar | `.searchable` |
  | Context menu | right-click | long-press lift-and-preview |
  | Quick Look | Spacebar | tap / peek |

### Never on iPhone — the gauche list

Hard “no,” because each would stick out as non-native: clickable column headers
or multi-column tables on a phone; a marquee on touch; a ⌘F bar instead of native
search; a “Customize Toolbar…” sheet; hand-placed spatial icon canvases; Mac
window chrome; and above all, *replacing* native iOS idioms (swipe actions,
pull-to-refresh, Edit mode, sheets, lift-and-preview) with Mac equivalents. The
test: **would a careful iOS developer recognize this as native?** If not,
MacAssed refuses to render it there.

## Platform matrix

| Affordance | macOS | iPadOS | iOS (phone) | visionOS |
|---|:--:|:--:|:--:|:--:|
| Column sort / resize / reorder | ● full | ● full | ○ collapses to `MAList` | ● full |
| ⇧ / ⌘ / marquee selection | ● | ● (+ pointer) | ◐ edit-mode multi | ● |
| Type-select | ● | ● (hardware kb) | ◐ when kb present | ● |
| Keyboard nav / menu commands | ● | ● | ◐ | ● |
| Context menus (selection-aware) | ● right-click | ● long-press | ● long-press | ● |
| Column autosave / view state | ● | ● | ● (sort only) | ● |
| Quick Look on Space | ● | ● | ◐ | ● |
| `MAChrome` period skins | ● | ● | ● | ○ (native only) |

● full · ◐ partial / input-dependent · ○ intentionally collapses

## Roadmap

Versioned by usefulness, not completeness. Each milestone is shippable.

- **v0.1 — The list problem, solved.** `MASort` + `MAFinderComparator`,
  `MASelection`, `MATable`/`MAList`, `MAColumnLayout` + autosave, `MACommands`,
  `.maTypeSelect`. This is the Gruber complaint, closed.
- **v0.2 — Manipulation.** `MAContextMenu` (selection-aware), `.maQuickLook`,
  `.maCopyAsTSV`, `.maFindBar`, `MAStatusBar`.
- **v0.3 — Structure & space.** `MASpatial` — the spatial Finder: window place
  memory + icon-position memory (`MASpatialView`), with Clean Up / Arrange By /
  Reset Layout. Then `MAOutline` (expand-all, persisted); `MADrag` — *not*
  reordering (Apple’s `.reorderable` covers that as of the 27 releases) but the
  parts it doesn’t: insertion-line indicators, spring-loaded folders, cross-app
  drags, and drag-session visibility polyfilled below macOS 26; and `MASidebar`
  badges.
- **v0.4 — Windows.** `.maCustomizableToolbar`, `MAInspector`/Get Info,
  `MAPanel`, proxy icons, `MADialog` defaults.
- **v0.5+ — Text & undo.** `MATokenField`, `MAComboBox`, `MAField` editor
  bindings, `MAUndo` named actions, `MAServices`.

Milestones map one-to-one onto Lost & Found sections, so “what’s left” is always
legible.

## Same orbit — what this is *not*

- **Paulo Andrade’s field notes** — “Using SwiftUI to Build a Mac-assed App in
  2026” and its [WWDC 26 update](https://pfandrade.me/blog/swiftui-mac-assed-wwdc26-update/)
  are the closest prior art, and effectively this project’s problem statement: a
  working Mac dev cataloguing exactly what pure SwiftUI still can’t do on the Mac
  (de-emphasized selection, context-menu targets, drag-session visibility,
  arrow-key *intent*, toolbar precision), radars filed. Gruber linked the first;
  an Apple engineer wrote back. MacAssed is one answer *in library form* to the
  gaps Andrade documents — where he says “track it yourself and pass it through
  the environment,” MacAssed is the packaged version of that advice.
- **[SwiftUIX](https://github.com/SwiftUIX/SwiftUIX)** — a broad library of
  *missing components* (controls SwiftUI never shipped). MacAssed overlaps at the
  edges but its center of gravity is different: *restoring interaction
  affordances and desktop-grade defaults*, not filling out the widget set.
  Use both; they’re complementary.
- **The “mac-arsed-mac-app” skill** (Reardon) — a kindred spirit in *guidance*
  form: how to build a Mac-assed app. MacAssed is the *library* form: code you
  link so you don’t have to hand-build each affordance. Guidance tells you what
  good looks like; MacAssed hands you the parts.
- **Apple itself.** WWDC 26 (the 27 releases) filled a few adjacent gaps —
  `.reorderable`/`.reorderContainer` (list/grid reordering), `.onDragSessionUpdated`
  (drag-session visibility, back-deployed to macOS 26), `.backgroundProminence`
  and `.appearsActive` (selection & window emphasis), and toolbar
  visibility/overflow APIs — but **none** of MacAssed’s core: sorting,
  type-select, the multi-select grammar, spatial memory, the find bar, or a
  user-customizable toolbar. MacAssed builds *on* the native APIs where they
  exist (see [Living alongside Apple](#living-alongside-apple--complement-then-back-deploy))
  and stays the sole provider where they don’t. And when Apple *does* fix a
  specific instance, it tends to be a point fix: the TestFlight sort regression
  that named this project was patched in TestFlight v4.3.1 on 3 September 2026 —
  roughly five weeks after the complaint — with no change to SwiftUI’s austere
  defaults. Apple whacks the loudest mole; the systemic gap remains, which is
  exactly what a library-level fix is for.

## Living alongside Apple — complement, then back-deploy

MacAssed never competes with a native API; it fills the space around one and
retreats as Apple advances. Three postures, chosen per affordance:

1. **Sole provider** — Apple ships nothing equivalent on any OS: Finder-order,
   secondary, and persisted sorting; type-select; marquee; invert; the find bar;
   column autosave; spatial memory. MacAssed implements these across its whole
   supported range. This is the raison d’être, and it doesn’t move.
2. **Polyfill, defer when native** — Apple shipped it recently, so it exists
   above some OS version: reordering (`.reorderable`/`.reorderContainer`, the 27
   releases), drag-session visibility (`.onDragSessionUpdated`, back-deployed to
   macOS 26), selection emphasis (`.backgroundProminence`). MacAssed exposes one
   stable call that uses the system implementation where present and its own
   below — so you write it once and it does the right thing per OS, and you
   inherit Apple’s polish and future improvements for free on new systems.
3. **Availability-gap smoother** — Apple has it on some platforms but not
   others. `.onMoveCommand` (arrow-key *intent*) is on macOS and tvOS but not
   iOS/iPadOS, so list navigation otherwise needs two code paths — Paulo
   Andrade’s exact gripe. MacAssed’s intent-level API picks the native one where
   it exists and a fallback (`.onKeyPress`) where it doesn’t, with no
   per-platform branching in app code.

The healthy consequence: MacAssed’s value is greatest on older OSes (it’s the
only source there) and narrows gracefully on newer ones (it defers). When Apple
finally ships, say, native type-select, MacAssed adds one `if #available` branch
and nothing in app code changes. That is what “live and flex with Swift
developments” means concretely.

### The mechanism (for folks coming from the web)

The web instinct is `@supports` (feature detection) or an `#ifdef` version gate.
Swift has both flavors, and the distinction is the whole game:

- **Compile-time — the `#ifdef` analogue.** `#if os(macOS)`,
  `#if canImport(AppKit)`, `#if swift(>=6.0)`. Decides what *compiles*. There is
  deliberately **no** compile-time “target OS ≥ 27” test: you build against one
  SDK and the binary runs on everything down to your deployment floor.
- **Runtime — the `@supports` analogue, and the one that matters here.**
  `if #available(macOS 27, *) { systemAPI() } else { maFallback() }`, plus
  `@available(…)` and `#unavailable(…)`. This *is* a polyfill: ship both paths,
  pick by the OS you’re **running on**. (There’s no “what’s on `PATH`” for UI
  APIs — availability is an OS-version question resolved at runtime, not a
  filesystem probe.)
- **The floor — how far back.** The deployment target in `Package.swift`
  (`platforms: [.macOS(.v14), …]`).
- **`@backDeployed`** (Swift 5.8+) ships a function whose *body* runs below its
  stated availability — handy for small conveniences; the heavy lifting still
  goes through `#available`.

### The floor, concretely

Two tracks, because the macOS AppKit bridge reaches further back than pure
SwiftUI:

- **Pure-SwiftUI paths** floor at **macOS 14 / iOS 17** — where `.onKeyPress`,
  `@Observable`, and Table column customization exist.
- **The macOS `NSTableView` bridge** can back-deploy list affordances to
  **macOS 12–13**, because AppKit already had them.

A common shipping norm (Andrade’s included) is “the latest two majors,” so the
window MacAssed most serves is exactly N‑2…N‑1 on the affordances Apple is only
now getting to. The pattern is sketched in
`Sources/MacAssed/Compatibility/MAAvailability.swift`.

## Open questions

Worth deciding in the open, with the community:

1. **AppKit bridge vs. pure SwiftUI on macOS.** The bridge is correct today but
   heavier; a pure-SwiftUI path may reach parity. Ship bridge-first, migrate
   behind the same API?
2. **`@Observable` selection model vs. value-type + binding.** `MASelection` is
   a value type now; some call sites may want a reference `@Observable`.
3. **How much undo to own.** Wrap `NSUndoManager`, or provide a portable undo?
4. **Theming surface.** How far does `MAChrome` go before it’s a design system
   of its own (a non-goal)?
5. **The floor, per track.** The strategy is set (see *Living alongside Apple*);
   the open call is the exact numbers: is the macOS 12–13 bridge back-deployment
   worth its complexity, or is a clean macOS 14 / iOS 17 floor the right v0.1
   line?
6. **Spatial’s blast radius.** How much should one `.spatial()` turn on — window
   reuse, frame memory, *and* the icon canvas — vs. each as its own opt-in? And
   how hard should multi-display window restoration try before it clamps?

Have an opinion? That’s what [CONTRIBUTING.md](CONTRIBUTING.md) is for.
