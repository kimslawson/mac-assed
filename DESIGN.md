# MacAssed — Design

The engineering spine. What the pieces are, why they're shaped this way, where
they run, and what order they get built in. For the *what-and-why-it-matters*,
start at [Lost & Found](docs/Lost-and-Found.md); for call sites, see
[Tools](docs/Tools.md) and [Examples](docs/Examples.md).

---

## Thesis

Modern minimalist interfaces have misplaced a lot of hard-won usability. SwiftUI
made building an app so frictionless that the path of least resistance now leads
to something austere — a `List` with no sort, no real multi-select, no
type-select, no memory. The affordances didn't get *rejected*; they got *skipped*,
because reaching for them stopped being the default.

MacAssed's bet: if the mac-assed affordances are the **easiest** thing to reach
for — one type name, sensible defaults, opt-out not opt-in — developers will use
them again, and a generation of apps gets its usability back.

## Design principles

1. **Opt-out, not opt-in.** The flagship controls ship with the full affordance
   set live. You remove what you don't want. Defaults are the product.
2. **Native by default, nostalgic by choice.** Out of the box, MacAssed looks
   like a 2026 Mac app. Period skins ([`MAChrome`](docs/Tools.md#chrome--machrome-opt-in))
   are opt-in and never change *which* affordances exist — only their looks.
3. **Behavior is UI-free.** Sorting, selection, column, and view-state logic
   live in `MacAssedCore` — plain Swift, `Sendable`, `Codable`, tested on Linux.
   The SwiftUI layer is a thin translation of gestures to that core.
4. **Graft, don't gut.** Every behavior is available as a standalone modifier so
   a team can adopt one thing without a rewrite.
5. **Persist by convention.** One `autosaveName` should bring a window back the
   way it was left — the AppKit contract, restored.
6. **Degrade honestly.** A multi-column table isn't right on iPhone; MacAssed
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

On macOS, `MATable`'s production implementation is backed by an `NSTableView`
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
  Reset Layout. Then `MAOutline` (expand-all, persisted), `MADrag` (insertion
  lines, spring-loading), `MASidebar` badges.
- **v0.4 — Windows.** `.maCustomizableToolbar`, `MAInspector`/Get Info,
  `MAPanel`, proxy icons, `MADialog` defaults.
- **v0.5+ — Text & undo.** `MATokenField`, `MAComboBox`, `MAField` editor
  bindings, `MAUndo` named actions, `MAServices`.

Milestones map one-to-one onto Lost & Found sections, so "what's left" is always
legible.

## Same orbit — what this is *not*

- **[SwiftUIX](https://github.com/SwiftUIX/SwiftUIX)** — a broad library of
  *missing components* (controls SwiftUI never shipped). MacAssed overlaps at the
  edges but its center of gravity is different: *restoring interaction
  affordances and desktop-grade defaults*, not filling out the widget set.
  Use both; they're complementary.
- **The "mac-arsed-mac-app" skill** (Reardon) — a kindred spirit in *guidance*
  form: how to build a Mac-assed app. MacAssed is the *library* form: code you
  link so you don't have to hand-build each affordance. Guidance tells you what
  good looks like; MacAssed hands you the parts.
- **Apple's own incremental additions** (`Table` sorting, `TableColumn`
  customization, `.inspector`) — genuinely good, and MacAssed builds *on* them
  where they exist rather than around them. The gap MacAssed fills is
  consistency, defaults, cross-platform reach, and the long tail Apple hasn't
  gotten to.

## Open questions

Worth deciding in the open, with the community:

1. **AppKit bridge vs. pure SwiftUI on macOS.** The bridge is correct today but
   heavier; a pure-SwiftUI path may reach parity. Ship bridge-first, migrate
   behind the same API?
2. **`@Observable` selection model vs. value-type + binding.** `MASelection` is
   a value type now; some call sites may want a reference `@Observable`.
3. **How much undo to own.** Wrap `NSUndoManager`, or provide a portable undo?
4. **Theming surface.** How far does `MAChrome` go before it's a design system
   of its own (a non-goal)?
5. **Minimum OS.** v0.1 targets macOS 14 for `.onKeyPress` and column
   customization. Is a macOS 13 back-deployment worth the bridge complexity?
6. **Spatial's blast radius.** How much should one `.spatial()` turn on — window
   reuse, frame memory, *and* the icon canvas — vs. each as its own opt-in? And
   how hard should multi-display window restoration try before it clamps?

Have an opinion? That's what [CONTRIBUTING.md](CONTRIBUTING.md) is for.
