//
//  MASelection.swift  ·  MacAssedCore
//
//  ┌─ API SKETCH ─────────────────────────────────────────────────────────┐
//  │ Design proposal. See docs/Tools.md § MASelection.                     │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  LOST: the full mouse+keyboard selection grammar every Mac user's fingers
//  already know —
//
//      click             → select one, set the anchor
//      ⇧-click           → extend a contiguous range from the anchor
//      ⌘-click           → toggle one, leaving the rest (discontiguous)
//      ⌘A / ⌘⇧A          → select all / deselect all
//      ↑ ↓  (⇧ extends)  → keyboard range selection
//      marquee drag       → rubber-band selection
//
//  SwiftUI's `Set<ID>` binding gives you the storage but none of the grammar:
//  no anchor, no ⇧-range on a `List`, no marquee, no invert.
//
//  FOUND: `MASelection` — the UI-free brain. The SwiftUI layer feeds it
//  gestures; it owns the pivot math.
//

import Foundation

/// Pivot-aware selection engine, generic over a `Hashable` row id. Stores ids
/// and their *visible order* only (never your model), so range math stays
/// correct as the list is filtered or re-sorted. Refresh `orderedIDs` whenever
/// the visible ordering changes.
public struct MASelection<ID: Hashable & Sendable>: Sendable {
    public private(set) var selected: Set<ID> = []
    public private(set) var anchor: ID?
    public var orderedIDs: [ID]

    public init(orderedIDs: [ID] = [], selected: Set<ID> = []) {
        self.orderedIDs = orderedIDs
        self.selected = selected
        self.anchor = selected.first
    }

    // MARK: Pointer grammar

    /// Plain click: this row alone, and the new anchor.
    public mutating func select(_ id: ID) { selected = [id]; anchor = id }

    /// ⌘-click: flip one row without disturbing the others.
    public mutating func toggle(_ id: ID) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
        anchor = id
    }

    /// ⇧-click: replace the transient range with anchor…id (inclusive).
    /// `additive` (⌘⇧-click) unions it, preserving discontiguous islands.
    public mutating func extend(to id: ID, additive: Bool = false) {
        guard let anchor, let lo = orderedIDs.firstIndex(of: anchor),
              let hi = orderedIDs.firstIndex(of: id) else { select(id); return }
        let range = orderedIDs[min(lo, hi)...max(lo, hi)]
        selected = additive ? selected.union(range) : Set(range)
        // Anchor stays put so successive ⇧-clicks keep pivoting from it.
    }

    // MARK: Keyboard grammar

    public enum Direction: Sendable { case up, down }

    public mutating func move(_ direction: Direction, extending: Bool) {
        guard !orderedIDs.isEmpty else { return }
        let step = direction == .down ? 1 : -1
        let current = selected.isEmpty ? nil : orderedIDs.lastIndex { selected.contains($0) }
        let next = ((current ?? -step) + step).clamped(to: 0...(orderedIDs.count - 1))
        let id = orderedIDs[next]
        extending ? extend(to: id) : select(id)
    }

    // MARK: Bulk grammar

    public mutating func selectAll()   { selected = Set(orderedIDs); anchor = orderedIDs.first }
    public mutating func deselectAll() { selected = []; anchor = nil }

    /// Invert — a Finder/Photoshop staple SwiftUI never shipped.
    public mutating func invert() { selected = Set(orderedIDs).subtracting(selected); anchor = nil }

    /// Rubber-band result: ids the marquee covered, unioned or replaced per the
    /// modifier held when the drag began.
    public mutating func marquee(_ ids: some Sequence<ID>, additive: Bool) {
        selected = additive ? selected.union(ids) : Set(ids)
    }
}

private extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self { min(max(self, r.lowerBound), r.upperBound) }
}
