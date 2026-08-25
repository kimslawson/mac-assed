# Lost & Found

*The things that somehow got lost along the way.*

MacAssed is an attempt to recover some of the functionality that modern
minimalist interfaces have misplaced. This page is the catalog — the inventory
of the Lost & Found drawer. Some of it was genuinely thrown out and has to be
rebuilt from scratch. A surprising amount of it is still in the building,
shoved in a back closet, one modifier away from working. We tag which is which:

| Tag | Meaning |
|-----|---------|
| 🔦 **From the depths** | Genuinely gone. SwiftUI offers no path. MacAssed rebuilds the behavior. |
| 🥾 **Needs a Swift kick** | SwiftUI *almost* has it — present but crippled, one-platform-only, or shipped with no default wiring. A nudge restores it. |

Each entry: what it was → where SwiftUI left it → the MacAssed tool that puts
it back. Tools are sketched in [Tools.md](Tools.md); proof it works in
[Examples.md](Examples.md).

---

## 1 · Sorting a list

- 🥾 **Sortable columns** — click a header to sort. `Table` has this via
  `sortOrder`, but only `Table`, only macOS, and it never remembers. → `MASort`, `MATable`
- 🥾 **Reversible sort** — click again to flip. Present in `Table`; absent
  everywhere a `List` is used, which is most apps. → `MATable`, `MAList`
- 🔦 **Finder-style natural order** — "Photo 2" before "Photo 10", case- and
  diacritic-insensitive. SwiftUI sorts lexicographically, so `10` sorts before
  `2`. This is the single most-felt loss. → `MAFinderComparator`
- 🔦 **Secondary / compound sort** — ⌥-click a second header: "by Size, then
  Name." No SwiftUI equivalent. → `MASort` (primary → secondary → …)
- 🔦 **Persisted sort** — the list comes back sorted how you left it. → `MAViewState`
- 🥾 **The sort indicator on custom headers** — the little triangle. `Table`
  draws one; you can't get it on your own header row. → `MAColumnHeader`

## 2 · Selecting things

- 🥾 **Multiple selection** — `Set<ID>` binding exists; the *grammar* doesn't. → `MASelection`
- 🔦 **⇧-click range** on a `List` — extend from an anchor. Works in `Table` on
  macOS, nowhere else. → `MASelection`
- 🔦 **⌘-click discontiguous** toggle — pick row 2, 5, and 9. → `MASelection`
- 🔦 **Marquee / rubber-band** — drag a rectangle across empty space. → `MASelection.marquee`
- 🔦 **Invert Selection** — a Finder/Photoshop staple. Nowhere in SwiftUI. → `MASelection.invert`
- 🥾 **Select All / Deselect All** — no menu items, no ⌘A wired by default. → `MACommands`
- 🔦 **Type-select** — type "wed" to jump to *Wednesday*. AppKit did this for
  free for 25 years. → `.maTypeSelect`

## 3 · The keyboard

- 🔦 **Arrow-key navigation** with ⇧ to extend, in *both* directions. → `MASelection.move`
- 🔦 **Home / End / Page Up / Page Down / ⌘↑ / ⌘↓** to the ends of a list. → `MATable`
- 🥾 **Return to open, Space to Quick Look** — the two most reflexive keys in
  the Finder, unbound by default. → `MATable`, `.maQuickLook`
- 🥾 **⌘⌫ to delete** with the expected confirm/undo. → `MACommands`
- 🔦 **Full keyboard access** — Tab reaching *every* control, not just text
  fields. The floor the rest stands on. → see §16

## 4 · Columns

- 🥾 **Resizing** — drag the divider. `Table` yes; `List` no; iPad no. → `MAColumnLayout`
- 🔦 **Size to Fit** — double-click a divider to fit the widest cell; ⌥ to fit
  all columns. → `MAColumnLayout.sizeToFit`
- 🥾 **Reordering** — drag a header. `TableColumnCustomization` (macOS 14+) can,
  clumsily; MacAssed makes it uniform and persistent. → `MAColumnLayout.move`
- 🥾 **Show / hide** — right-click the header, check a column off. Partial in
  `Table`; MacAssed adds the menu and the "Customize…" sheet. → `MAColumnLayout`
- 🔦 **Column autosave** — widths + order + visibility, remembered under a name,
  forever, per user. AppKit's `autosaveName`, gone. → `MAViewState`
- 🔦 **Frozen header / first column** on scroll. → `MATable`

## 5 · Menus & commands

- 🥾 **Contextual (right-click) menus** — `.contextMenu` exists but is per-row
  and *forgets the selection* (right-click one of three selected rows and the
  menu acts on one). → `MAContextMenu` (selection-aware)
- 🔦 **Secondary-click that reflects multi-selection** — "Delete 3 Items". → `MAContextMenu`
- 🥾 **A complete Edit menu** — Undo/Redo, Cut/Copy/Paste/Delete, Select All,
  Invert. SwiftUI ships the easy half. → `MACommands`
- 🔦 **Named undo** — "Undo Rename", "Undo Move", with `NSUndoManager`
  semantics and mixed-state menu items (✓ / – ). → `MAUndo` *(roadmap)*
- 🔦 **View ▸ Sort By ▸** and **View ▸ Columns ▸** menus with ⌘-equivalents. → `MACommands`
- 🔦 **Services & Sharing** menu integration. → `MAServices` *(roadmap)*

## 6 · Direct manipulation

- 🥾 **Drag to reorder / into / out of** — `.draggable`/`.dropDestination` exist;
  reorder is hand-rolled every time and cross-app drags are rare. → `MADrag` *(roadmap)*
- 🔦 **Insertion-line drop indicator** vs. container-highlight — the two distinct
  "where will this land" cues. → `MADrag` *(roadmap)*
- 🔦 **Spring-loaded folders** — hover a folder mid-drag and it opens. Peak Mac.
  → `MADrag` *(roadmap)*
- 🥾 **Quick Look** — `.quickLookPreview` exists but isn't bound to Space over a
  selection, with ←/→ to walk it. → `.maQuickLook`
- 🔦 **Cursor rects & help tags** — I-beam / resize cursors, and a tooltip on
  truncated text so you can actually read it. → `MATooltip` *(roadmap)*

## 7 · Disclosure & outlines

- 🥾 **Disclosure triangles** — `OutlineGroup`/`DisclosureGroup` exist. → `MAOutline`
- 🔦 **Expand All / Collapse All**, and ⌥-click to expand an entire subtree. → `MAOutline`
- 🔦 **Persisted expansion state** — the tree remembers what was open. → `MAViewState`
- 🔦 **Indentation guides** and consistent disclosure hit-targets. → `MAOutline`

## 8 · Search & filter

- 🥾 **⌘F Find bar** — the slide-down, live-filtering bar over *your* data.
  `.searchable` is a search *field*, not this. → `.maFindBar`
- 🔦 **Scope bar** — "All / Name / Contents" buttons. → `.maFindBar(scopes:)`
- 🔦 **Result count & Find Next (⌘G)** — "3 of 12". → `.maFindBar`
- 🔦 **Filter tokens / smart-folder predicates**. → `MAFilter` *(roadmap)*

## 9 · Windows & documents

- 🥾 **Window frame autosave** — SwiftUI mostly remembers size/position, but the
  named, per-window control (and multi-window discipline) is gone. → `MAViewState`
- 🔦 **Proxy icon** in the title bar — drag the document out, ⌘-click for the
  path popup. → `MAWindow` *(roadmap)*
- 🔦 **Edited indicator** — the dot in the close button; Revert / Versions. → `MAWindow` *(roadmap)*
- 🔦 **Utility & inspector panels** — floating, non-activating `NSPanel` / HUD
  windows. SwiftUI has no panel concept. → `MAPanel` *(roadmap)*
- 🥾 **Default & Cancel buttons** in dialogs — the pulsing default, Esc to
  cancel, ⏎ to confirm. Easy to get wrong, easy to standardize. → `MADialog` *(roadmap)*

## 10 · Toolbars

- 🔦 **User-customizable toolbar** — the "Customize Toolbar…" sheet, drag items
  in and out. SwiftUI toolbars are developer-fixed. → `.maCustomizableToolbar`
- 🔦 **Icon Only / Text Only / Icon & Text** modes + small size. → `.maCustomizableToolbar`
- 🥾 **Overflow chevron** when the window narrows — SwiftUI does some of this;
  make it predictable. → `.maCustomizableToolbar`

## 11 · Inspectors & Get Info

- 🥾 **Inspector pane** — `.inspector` exists (macOS 14). → `MAInspector`
- 🔦 **Get Info (⌘I)** panel per item. → `MAInspector` *(roadmap)*
- 🔦 **Multi-selection inspector** — "Multiple Values" placeholders; an edit
  applies to the whole selection. → `MAInspector` *(roadmap)*

## 12 · Sidebars & status

- 🥾 **Source-list sidebar** — SwiftUI has `.sidebar` list style. → `MASidebar`
- 🔦 **Badges / counts** on sidebar rows (the unread bubble). → `MASidebar` *(roadmap)*
- 🔦 **Status bar** — "1,204 items, 3 selected", live. You rebuild it every app. → `MAStatusBar`
- 🥾 **Real progress in context** — determinate bars and counts, not just a
  spinner. → `MAStatusBar` *(roadmap)*

## 13 · Text & fields

- 🔦 **Field-editor bindings** — ⌥-arrow by word, ⌃A/⌃E to line ends, the
  emacs-isms every macOS text field has had forever. → `MAField` *(roadmap)*
- 🔦 **Token fields** — the Mail "To:" pill field. → `MATokenField` *(roadmap)*
- 🔦 **Combo box** — editable text + dropdown list in one. → `MAComboBox` *(roadmap)*
- 🥾 **Tab / ⇧-Tab field navigation** and ⏎-to-commit in forms. → `MAForm` *(roadmap)*

## 14 · Copy, paste & the clipboard

- 🔦 **Copy as TSV/CSV** — select rows, ⌘C, paste into Numbers intact. Today you
  usually get nothing. → `.maCopyAsTSV`
- 🔦 **Rich multi-representation drags** — one drag that a spreadsheet, a text
  editor, and the Finder each interpret correctly. → `MADrag` *(roadmap)*

## 15 · The look *(opt-in)*

- 🔦 **Affordance-by-appearance** — a header that *looks* clickable, a divider
  that *looks* draggable. Flatness removed the visual cues that taught the
  gestures. MacAssed's default look restores the cues without going full retro. → `MAChrome`
- 🔦 **Alternating rows, grid lines, density** — zebra striping beyond `Table`,
  compact/regular row heights. → `MAChrome`
- 🔦 **Nostalgia skins** — Platinum and Aqua, for people who want them.
  Tasteful, switchable, never kitsch. → `MAChrome(.platinum)` / `.aqua`

## 16 · The floor: accessibility & system fit

Not nostalgia — the baseline the rest depends on. Every affordance MacAssed
restores ships with:

- 🔦 **Full keyboard operability** (VoiceOver too) — the prerequisite that makes
  type-select, arrow-nav, and menu shortcuts real rather than decorative.
- 🥾 **Respect for Reduce Motion / Increase Contrast / Dynamic Type** and RTL
  mirroring — SwiftUI gives you the hooks; MacAssed wires its controls to them.
- 🥾 **VoiceOver labels & traits** on restored controls, so a sortable header
  announces itself as one.

---

## What we're *not* trying to recover

Some things were left behind on purpose, and MacAssed doesn't relitigate them:
spatial-Finder window sprawl, the Classic control panel maze, forcing every app
into a document model, or reflexive skeuomorphism. The test for the drawer isn't
"was it old," it's **"did a real task get harder when it went."**

## Something missing from the drawer?

This catalog is meant to grow with the community. If a table-stakes affordance
you miss isn't here, that's a
[Lost & Found claim ticket](../CONTRIBUTING.md) waiting to be filed.
