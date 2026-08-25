//
//  MASpatial.swift  ·  MacAssed
//
//  ┌─ API SKETCH ─────────────────────────────────────────────────────────┐
//  │ Design proposal. See docs/Tools.md § MASpatial. Bodies illustrative.  │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  The spatial Finder, recovered. Two halves:
//
//    • `.spatial()`      — a Scene modifier: one window per place, each window
//                          reopening where you left it, opening a place again
//                          bringing its window forward instead of duplicating.
//    • `MASpatialView`   — an icon view where positions *stick*. Drop an icon
//                          and it stays; new items land in the first free grid
//                          slot; hand-placed icons never re-flow.
//
//  Native by default, nostalgic by choice: you opt into spatial mode. Window-
//  frame memory is safe to default on; icon memory is the default *within* this
//  view — choosing `MASpatialView` is itself the opt-in.
//

import SwiftUI
import MacAssedCore

// MARK: - The icon canvas

/// A free-position icon view backed by a persistable `MASpatialLayout`. Marquee
/// selection comes from `MASelection`; Clean Up / Arrange come from
/// `MASpatialCommands`.
public struct MASpatialView<Item: Identifiable & Sendable, Cell: View>: View {
    private let items: [Item]
    @Binding private var selection: Set<Item.ID>
    @Binding private var layout: MASpatialLayout
    private let cell: (Item) -> Cell

    var autosaveName: String?
    var snapOnDrop = false

    public init(
        _ items: [Item],
        selection: Binding<Set<Item.ID>>,
        layout: Binding<MASpatialLayout>,
        @ViewBuilder cell: @escaping (Item) -> Cell
    ) {
        self.items = items; self._selection = selection
        self._layout = layout; self.cell = cell
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                MADotGrid(grid: layout.grid)                 // the faint icon-view grid
                ForEach(items) { item in
                    let p = point(for: item)
                    cell(item)
                        .frame(width: layout.grid.iconSize)
                        .position(x: p.x + layout.grid.iconSize / 2,
                                  y: p.y + layout.grid.iconSize / 2)
                        .gesture(drag(item, in: geo.size))
                }
            }
            // .background(marquee(via: MASelection)) — rubber-band lives here
        }
        .task(id: autosaveName) { restore(columns: nil) }
    }

    private func point(for item: Item) -> MAPoint {
        let key = String(describing: item.id)
        if let p = layout.positions[key] { return p }
        var l = layout; l.place(key); layout = l          // first free slot, once
        return layout.positions[key] ?? .init()
    }

    private func drag(_ item: Item, in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { g in setPosition(item, to: g.location, in: size, snap: false) }
            .onEnded   { g in setPosition(item, to: g.location, in: size, snap: snapOnDrop) }
    }

    private func setPosition(_ item: Item, to loc: CGPoint, in size: CGSize, snap: Bool) {
        let key = String(describing: item.id)
        let s = layout.grid.iconSize
        var p = MAPoint(x: Double(min(max(0, loc.x - s/2), size.width  - s)),
                        y: Double(min(max(0, loc.y - s/2), size.height - s)))
        if snap { p = layout.grid.snap(p) }
        var l = layout; l.positions[key] = p; layout = l   // persisted by MAViewState
    }

    private func restore(columns: Int?) {
        guard let name = autosaveName else { return }
        if let l = MAUserDefaultsStore(autosaveName: name).load(MASpatialLayout.self, for: "spatial") {
            layout = l
        }
        // …and a sink writing layout changes straight back.
    }
}

public extension MASpatialView {
    /// Persist positions + grid under this autosave name.
    func spatialAutosave(_ name: String) -> Self { var c = self; c.autosaveName = name; return c }
    /// Snap to grid on drop (vs. free placement). Off by default — true spatial.
    func iconGrid(snap: Bool) -> Self { var c = self; c.snapOnDrop = snap; return c }
}

// MARK: - The scene modifier (window place memory)

public extension Scene {
    /// Opt this scene into the spatial window model: one window per place,
    /// frame-per-place memory, and bring-forward on re-open.
    ///
    /// SwiftUI's `WindowGroup(for:)` already reuses a window per value — the
    /// bones of one-window-per-folder. `.spatial()` layers on the frame
    /// persistence (via `MAWindowState`, keyed to the place id) and, on macOS,
    /// bridges to `NSWindow.setFrameAutosaveName` for pixel-true restoration.
    func spatial() -> some Scene { self }   // sketch: wraps scene restoration + frame autosave
}

// MARK: - The clean-up kit as menu commands

/// View ▸ Clean Up / Arrange By ▸ / Keep Arranged By ▸ / Reset Layout, wired to
/// the focused `MASpatialView`. Compose alongside `MACommands`.
public struct MASpatialCommands: Commands {
    public init() {}
    public var body: some Commands {
        CommandGroup(after: .toolbar) {
            Menu("Icon Arrangement") {
                Button("Clean Up")           { MASpatialAction.cleanUp.send() }
                Button("Clean Up Selection") { MASpatialAction.cleanUpSelection.send() }
                Divider()
                Menu("Arrange By") {
                    Button("Name") { MASpatialAction.arrange("name").send() }
                    Button("Kind") { MASpatialAction.arrange("kind").send() }
                    Button("Size") { MASpatialAction.arrange("size").send() }
                    Button("Date Modified") { MASpatialAction.arrange("modified").send() }
                }
                Button("Reset Layout") { MASpatialAction.reset.send() }   // undo an arrange
                    .keyboardShortcut("r", modifiers: [.command, .option])
            }
        }
    }
}

enum MASpatialAction: Sendable {
    case cleanUp, cleanUpSelection, reset
    static func arrange(_ field: String) -> MASpatialAction { .cleanUp } // sketch token
    func send() { /* forwards to the focused MASpatialView via FocusedValues */ }
}

// Faint dotted icon-view grid. Illustrative.
struct MADotGrid: View { let grid: MAGrid; var body: some View { Color.clear } }
