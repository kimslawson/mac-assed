//
//  MASort.swift  ·  MacAssedCore
//
//  ┌─ API SKETCH ─────────────────────────────────────────────────────────┐
//  │ Design proposal. Public surface is drawn out; bodies are illustrative.│
//  │ See docs/Tools.md § MASort and docs/Lost-and-Found.md § "The sort".   │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  LOST: NSSortDescriptor, multi-key sort stacks, and Finder's numeric-aware,
//  case/diacritic-insensitive string ordering — the reason "Photo 2.png" sorts
//  before "Photo 10.png" in the Finder and *after* it in a naive SwiftUI Table.
//
//  FOUND: `MASortDescriptor` (the persistable per-level unit — the name is a
//  deliberate nod to NSSortDescriptor), `MASort` (the primary→secondary→…
//  stack), and `MAFinderComparator` (ordering that actually sorts like a Mac).
//

import Foundation

// MARK: - MAFinderComparator

/// A `SortComparator` that orders strings the way the Finder does: numeric-
/// aware ("file2" < "file10"), case- and width-insensitive, locale-sensitive.
/// Backed by `localizedStandardCompare` — the same call AppKit column sorts use.
public struct MAFinderComparator: SortComparator, Sendable {
    public var order: SortOrder
    public init(order: SortOrder = .forward) { self.order = order }

    public func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let r = lhs.localizedStandardCompare(rhs)
        return order == .forward ? r : r.reversed
    }
}

private extension ComparisonResult {
    var reversed: ComparisonResult {
        self == .orderedAscending ? .orderedDescending
            : self == .orderedDescending ? .orderedAscending : .orderedSame
    }
}

// MARK: - MASortDescriptor

/// One level of a sort: a named, `Codable`-shadowable key plus a direction.
/// Unlike a bare `KeyPathComparator`, it carries a stable `id` (the autosave
/// token) and a menu `title`, so "Sort By ▸ Size" and a restored-on-launch
/// sort both refer to the same thing.
public struct MASortDescriptor<Element>: Identifiable, Sendable {
    public let id: String
    public let title: String
    public var order: SortOrder
    let compare: @Sendable (Element, Element, SortOrder) -> ComparisonResult

    public init<Value>(
        _ id: String, _ title: String,
        _ keyPath: KeyPath<Element, Value> & Sendable,
        using comparator: some SortComparator<Value>,
        order: SortOrder = .forward
    ) {
        self.id = id; self.title = title; self.order = order
        self.compare = { a, b, o in
            var c = comparator; c.order = o
            return c.compare(a[keyPath: keyPath], b[keyPath: keyPath])
        }
    }

    /// The common case: a `String` field sorted Finder-style.
    public static func finder(
        _ id: String, _ title: String, _ keyPath: KeyPath<Element, String> & Sendable
    ) -> MASortDescriptor { .init(id, title, keyPath, using: MAFinderComparator()) }
}

// MARK: - MASort (the stack)

/// The ordered stack of sort levels — primary, secondary, tertiary…
///
///   • click a header          → `setPrimary`  (re-click flips direction)
///   • ⌥-click a header         → `addSecondary` (compound sort, classic list view)
///
/// `MASort` is the model the header gestures drive; it produces a *stable*
/// multi-key comparison and projects to a `Codable` shadow for autosave.
public struct MASort<Element>: Sendable {
    public private(set) var levels: [MASortDescriptor<Element>]
    public init(_ levels: [MASortDescriptor<Element>] = []) { self.levels = levels }

    public mutating func setPrimary(_ field: MASortDescriptor<Element>) {
        if let top = levels.first, top.id == field.id {
            levels[0].order = top.order == .forward ? .reverse : .forward
        } else {
            var f = field
            if let existing = levels.first(where: { $0.id == field.id }) { f.order = existing.order }
            levels = [f]
        }
    }

    public mutating func addSecondary(_ field: MASortDescriptor<Element>) {
        levels.removeAll { $0.id == field.id }
        levels.append(field)
    }

    public func areInIncreasingOrder(_ a: Element, _ b: Element) -> Bool {
        for level in levels {
            switch level.compare(a, b, level.order) {
            case .orderedAscending:  return true
            case .orderedDescending: return false
            case .orderedSame:       continue
            }
        }
        return false
    }
}

public extension Sequence {
    /// Stable, O(n log n) multi-key sort honoring every level of an `MASort`.
    func sorted(by sort: MASort<Element>) -> [Element] {
        enumerated()
            .sorted { l, r in
                switch (sort.areInIncreasingOrder(l.element, r.element),
                        sort.areInIncreasingOrder(r.element, l.element)) {
                case (true, _):     return true
                case (false, true): return false
                default:            return l.offset < r.offset   // stability
                }
            }
            .map(\.element)
    }
}

// MARK: - Codable shadow (autosave)

/// Persists ids + directions only, re-hydrated against the live descriptor set —
/// so renaming a column title never corrupts a saved sort.
public struct MASortState: Codable, Equatable, Sendable {
    public struct Level: Codable, Equatable, Sendable {
        public var fieldID: String
        public var ascending: Bool
    }
    public var levels: [Level]
    public init(levels: [Level] = []) { self.levels = levels }
}
