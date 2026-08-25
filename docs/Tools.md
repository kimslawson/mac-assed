# Tools

*Things MacAssed gives you to put them back.*

The toolbox, grouped by how you reach for it. Everything here is an **API
sketch** — the shapes are settled, the bodies are being built (see
[project status](../README.md#status)). Each tool names the
[Lost & Found](Lost-and-Found.md) entries it restores.

Two ideas run through all of it:

1. **Batteries included, opt-out not opt-in.** `MATable` ships with sort,
   multi-select, type-select, keyboard nav, and TSV-copy *on*. You remove what
   you don’t want; you don’t assemble what you do.
2. **A UI-free core.** Every behavior lives in `MacAssedCore` as plain Swift you
   can test on Linux. `import MacAssed` for the views; `import MacAssedCore` for
   just the brains.

---

## The flagship — `MATable`

A sortable, multi-select, column-managed, self-persisting table one type name
away from a plain list.

```swift
import MacAssed

MATable(inbox, selection: $selection) {
    MAColumn("Name",     value: \.name)              // Finder-sorted; type-select target
    MAColumn("From",     value: \.sender)
    MAColumn("Received", value: \.date) { Text($0.date, format: .relative(presentation: .named)) }
    MAColumn("Size",     value: \.size, align: .trailing).width(min: 64, ideal: 80)
}
.columnAutosave("Inbox")            // widths · order · visibility · sort — remembered
.rowContextMenu { rows in ReplyButton(rows); ArchiveButton(rows) }
.tableStatusBar()                   // "1,204 messages, 3 selected"
```

Restores: **§1** sorting · **§2** selection · **§3** keyboard · **§4** columns.

- `.columnAutosave(_:)` — the AppKit `autosaveName`, back.
- `.rowContextMenu { selection in … }` — a menu that receives the *whole*
  selection, so batch actions work.
- `.tableStatusBar()` — the live item/selection count.
- `.tableStyle(_:)` — `.automatic` (default), `.insetAlternating`, `.classicAqua`.

## The smaller sibling — `MAList`

One column, same grammar. The right answer on iPhone and for anything that isn’t
tabular.

```swift
MAList(notes, selection: $selection,
       sortedBy: [.finder("title", "Title", \.title),
                  MASortDescriptor("edited", "Date Edited", \.editedAt, using: .init())]) { note in
    NoteRow(note)
}
```

Restores: **§1**, **§2**, **§3**.

---

## The engine (`MacAssedCore`) — behavior without our views

### `MASort` · `MASortDescriptor` · `MAFinderComparator`
The sort stack. `MASortDescriptor` is the persistable per-level unit (the name
nods to `NSSortDescriptor`); `MASort` stacks them primary → secondary; and
`MAFinderComparator` is the numeric-aware, case/diacritic-insensitive ordering
that makes lists sort like a Mac.

```swift
var sort = MASort<File>()
sort.setPrimary(.finder("name", "Name", \.name))   // click; re-click flips
sort.addSecondary(.finder("kind", "Kind", \.kind)) // ⌥-click
let ordered = files.sorted(by: sort)               // stable, O(n log n)
```
Restores: **§1**.

### `MASelection`
The pointer + keyboard selection grammar as a pure model: anchor, ⇧-range,
⌘-toggle, marquee, invert, arrow-move. Feed it gestures; read `.selected`.

```swift
var sel = MASelection(orderedIDs: visibleIDs)
sel.select(id)                 // click
sel.extend(to: id)             // ⇧-click
sel.toggle(id)                 // ⌘-click
sel.marquee(hitIDs, additive: shiftHeld)
sel.invert()
```
Restores: **§2**, **§3**.

### `MAColumnSpec` · `MAColumnLayout`
The fixed column contract and the mutable, `Codable` layout (order, widths,
visibility) keyed by autosave name. `reconcile(with:)` keeps saved layouts valid
as an app’s columns change.
Restores: **§4**.

### `MAViewState`
`MAViewStateStore` — one autosave name, one `Codable` blob. Default backing is
JSON in `UserDefaults` under a `MacAssed.<name>.` prefix; swap in SwiftData or
iCloud. `MAWindowState` bundles columns + sort + expansion + sidebar width +
frame + (opt-in) selection.
Restores: **§1** persisted sort · **§4** autosave · **§7** expansion · **§9** frame.

---

## Grafting modifiers — one behavior, no rewrite

For the `List` you already ship. Each is independent.

```swift
List(files, selection: $sel) { … }
    .maTypeSelect(files, id: \.id, text: \.name, selection: $sel)  // §2 type-select
    .maSelection($sel, orderedIDs: files.map(\.id))               // §2 full grammar
    .maQuickLook(sel) { url(for: $0) }                           // §6 Space = Quick Look
    .maCopyAsTSV(files, columns: [("Name", \.name), ("Size", \.sizeString)]) // §14
```

## Menus & find — `MACommands`, `.maFindBar`

```swift
WindowGroup { … }
    .commands { MACommands() }          // §5 Sort By ▸, Select All, Invert, Columns ▸

ContentView()
    .maFindBar(text: $query,            // §8 ⌘F slide-down bar, live filter
               scopes: [(.all, "All"), (.name, "Name")], scope: $scope)
```

## Context menus — `MAContextMenu`

Selection-aware right-click. Unlike `.contextMenu`, it keeps the full selection
and pluralizes.

```swift
.maContextMenu(selection: $sel) { ids in
    Button("Get Info")               { … }
    Button("Delete \(ids.count) Items", role: .destructive) { … }
}
```
Restores: **§5**.

## Chrome — `MAChrome` *(opt-in)*

Behavior everywhere else defaults to native looks; this is the only nostalgia
knob, and it’s off unless you turn it on.

```swift
MATable(…) { … }.maChrome(.system)     // default — today's native look
MATable(…) { … }.maChrome(.platinum)   // Mac OS 8/9
MATable(…) { … }.maChrome(.aqua)       // early Mac OS X
```
Restores: **§15**.

## Spatial — `MASpatial` *(roadmap · v0.3)*

The spatial Finder, recovered — window place memory and icon-position memory,
the way John Siracusa always wanted it.

```swift
// Opt an app into the spatial window model at the scene level:
WindowGroup(for: Folder.ID.self) { $id in FolderView(id) }
    .spatial()   // one window per folder · frame-per-folder memory · bring-forward

// The icon view where positions stick:
MASpatialView(items, selection: $sel, layout: $layout) { IconCell($0) }
    .spatialAutosave("Projects")
    // new items → first free slot; hand-placed icons never re-flow; marquee via MASelection

// The escape hatches (View ▸ and context menu), via MASpatialCommands:
//   Clean Up · Clean Up Selection · Arrange By ▸ · Keep Arranged By ▸ · Reset Layout
```

Behavior is `MASpatialLayout` in `MacAssedCore` — `Codable` positions + grid,
with `cleanUp()`, `arrange(order:)`, and a snapshot so **Reset Layout** can undo
an Arrange. Icon positions are content-relative and so display-independent.
Restores: **§17**.

---

## On the roadmap

Sketched in Lost & Found, not yet in the toolbox: `MAOutline` (§7),
`MADrag` (§6), `MAWindow` / `MAPanel` / `MADialog` (§9), `MAInspector` (§11),
`MASidebar` (§12), `MATokenField` / `MAComboBox` / `MAField` (§13), `MAUndo` &
`MAServices` (§5). Priorities live in [DESIGN.md § Roadmap](../DESIGN.md#roadmap);
claim one in [CONTRIBUTING.md](../CONTRIBUTING.md).
