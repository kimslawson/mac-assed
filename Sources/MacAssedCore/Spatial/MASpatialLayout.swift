//
//  MASpatialLayout.swift  ·  MacAssedCore
//
//  ┌─ API SKETCH ─────────────────────────────────────────────────────────┐
//  │ Design proposal. See docs/Tools.md § MASpatial and                    │
//  │ docs/Lost-and-Found.md § 17 “Spatial memory”.                         │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  LOST: the spatial Finder. One window per folder, each reopening where you
//  left it; every icon staying exactly where you put it. You navigated by
//  muscle memory, because a place was a *place*. John Siracusa argued the case
//  for decades (“About the Finder…”, 2003); Mac OS X’s navigational Finder
//  threw most of it away.
//
//  FOUND: `MASpatialLayout` — the UI-free, `Codable` model of a spatial view.
//  Icon positions are window-content-relative, so this half is entirely
//  display-independent: it survives monitor changes untouched. (The window-
//  placement half lives in `MAWindowState.windowFrame`; only *that* carries the
//  multi-display asterisk.)
//

import Foundation

/// A point in a spatial view’s content space. A small `Codable` value type so
/// Core stays testable anywhere (no reliance on CGPoint’s platform conformances).
public struct MAPoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double = 0, y: Double = 0) { self.x = x; self.y = y }
}

/// The grid a spatial view snaps to and flows new items into.
public struct MAGrid: Codable, Equatable, Sendable {
    public var cell: Double        // pitch between slot origins
    public var iconSize: Double
    public var columns: Int
    public var inset: Double

    public init(cell: Double = 96, iconSize: Double = 72, columns: Int = 6, inset: Double = 12) {
        self.cell = cell; self.iconSize = iconSize; self.columns = max(1, columns); self.inset = inset
    }

    /// Row-major origin of the i-th grid slot.
    public func point(forSlot i: Int) -> MAPoint {
        let r = i / columns, c = i % columns
        return MAPoint(x: inset + Double(c) * cell, y: inset + Double(r) * cell)
    }

    /// Nearest slot origin to an arbitrary point — the math behind “Clean Up”.
    public func snap(_ p: MAPoint) -> MAPoint {
        let c = ((p.x - inset) / cell).rounded()
        let r = ((p.y - inset) / cell).rounded()
        return MAPoint(x: inset + max(0, c) * cell, y: inset + max(0, r) * cell)
    }

    /// Which slot index a point currently occupies (for free-slot search).
    public func slotIndex(_ p: MAPoint) -> Int {
        let c = Int(max(0, ((p.x - inset) / cell).rounded()))
        let r = Int(max(0, ((p.y - inset) / cell).rounded()))
        return r * columns + c
    }
}

/// The persistable spatial layout: where each item sits, the grid, and whether
/// the view is auto-arranging. Keyed by autosave name via `MAViewState`.
public struct MASpatialLayout: Codable, Equatable, Sendable {
    public var positions: [String: MAPoint]
    public var grid: MAGrid
    /// `nil` = free / hand-placed (true spatial). Non-nil = auto-arranged by a
    /// field id (“Keep Arranged By ▸ Name”).
    public var keepArrangedBy: String?
    /// The last hand-placed layout, captured before an Arrange, so “Reset
    /// Layout” can bring it back. A hand-placed layout is precious.
    public var snapshot: [String: MAPoint]?

    public init(positions: [String: MAPoint] = [:], grid: MAGrid = MAGrid(),
                keepArrangedBy: String? = nil) {
        self.positions = positions; self.grid = grid; self.keepArrangedBy = keepArrangedBy
    }

    // MARK: New-item placement

    /// Place a newly-appeared item in the first free grid slot — so existing,
    /// hand-placed icons never shuffle when the folder gains a file.
    public mutating func place(_ id: String) {
        guard positions[id] == nil else { return }
        var occupied = Set(positions.values.map { grid.slotIndex($0) })
        var i = 0
        while occupied.contains(i) { i += 1 }
        occupied.insert(i)
        positions[id] = grid.point(forSlot: i)
    }

    // MARK: The clean-up kit (classic Finder canon)

    /// “Clean Up” — snap everything (or just `ids`) to the grid, preserving the
    /// rough arrangement. Non-destructive: no reordering.
    public mutating func cleanUp(_ ids: Set<String>? = nil) {
        for (id, p) in positions where ids?.contains(id) ?? true {
            positions[id] = grid.snap(p)
        }
    }

    /// “Arrange By ▸” — reflow a sorted order into row-major slots. The caller
    /// sorts (via `MASort`) and passes the ordered ids, keeping Core decoupled
    /// from element types. Snapshots first so the hand-placed layout is
    /// recoverable.
    public mutating func arrange(order: [String]) {
        if snapshot == nil { snapshot = positions }
        for (i, id) in order.enumerated() { positions[id] = grid.point(forSlot: i) }
    }

    /// “Reset Layout” / Undo Arrange — restore the last hand-placed layout.
    @discardableResult
    public mutating func restoreSnapshot() -> Bool {
        guard let s = snapshot else { return false }
        positions = s; snapshot = nil; return true
    }
}
