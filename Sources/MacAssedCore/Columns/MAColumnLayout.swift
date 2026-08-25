//
//  MAColumnLayout.swift  ·  MacAssedCore
//
//  ┌─ API SKETCH ─────────────────────────────────────────────────────────┐
//  │ Design proposal. See docs/Tools.md § MAColumn.                        │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  LOST: column management as a first-class, persistent thing — drag to
//  reorder, drag the divider to resize, right-click the header to show/hide,
//  double-click a divider to “size to fit”, all remembered under an autosave
//  name. NSTableView shipped this in 1997. SwiftUI’s `Table` only began
//  restoring pieces (hide/reorder via `TableColumnCustomization`) in macOS 14,
//  and still can’t on a `List` or on iPad.
//
//  FOUND: `MAColumnSpec` (the fixed contract) + `MAColumnLayout` (the mutable,
//  persistable state keyed by autosave name). Both UI-free, so one model can
//  drive an MATable, a List header row, or a custom grid.
//

import Foundation

public typealias MAColumnID = String

/// The immutable description of a column — the parts that don’t change when the
/// user drags things around.
public struct MAColumnSpec: Identifiable, Sendable {
    public let id: MAColumnID
    public var title: String
    public var alignment: Alignment
    public var min: CGFloat
    public var ideal: CGFloat
    public var max: CGFloat
    /// A column a user can never hide — there must always be something to click.
    public var isRequired: Bool
    public var isSortable: Bool

    public enum Alignment: String, Codable, Sendable { case leading, center, trailing }

    public init(
        _ id: MAColumnID, title: String, alignment: Alignment = .leading,
        min: CGFloat = 40, ideal: CGFloat = 120, max: CGFloat = .infinity,
        isRequired: Bool = false, isSortable: Bool = true
    ) {
        self.id = id; self.title = title; self.alignment = alignment
        self.min = min; self.ideal = ideal; self.max = max
        self.isRequired = isRequired; self.isSortable = isSortable
    }
}

/// The mutable, persistable layout: order, widths, visibility. This is the
/// thing keyed by autosave name and re-hydrated on launch.
public struct MAColumnLayout: Codable, Equatable, Sendable {
    public var order: [MAColumnID]
    public var widths: [MAColumnID: CGFloat]
    public var hidden: Set<MAColumnID>

    public init(order: [MAColumnID] = [], widths: [MAColumnID: CGFloat] = [:], hidden: Set<MAColumnID> = []) {
        self.order = order; self.widths = widths; self.hidden = hidden
    }

    public static func `default`(from specs: [MAColumnSpec]) -> MAColumnLayout {
        MAColumnLayout(order: specs.map(\.id),
                       widths: Dictionary(uniqueKeysWithValues: specs.map { ($0.id, $0.ideal) }))
    }

    public var visibleOrder: [MAColumnID] { order.filter { !hidden.contains($0) } }

    // MARK: Header gestures

    public mutating func move(_ id: MAColumnID, before other: MAColumnID) {
        guard let from = order.firstIndex(of: id) else { return }
        order.remove(at: from)
        order.insert(id, at: order.firstIndex(of: other) ?? order.endIndex)
    }

    public mutating func setHidden(_ id: MAColumnID, _ hidden: Bool, specs: [MAColumnSpec]) {
        guard !(specs.first { $0.id == id }?.isRequired ?? false) else { return }
        if hidden { self.hidden.insert(id) } else { self.hidden.remove(id) }
    }

    public mutating func resize(_ id: MAColumnID, to width: CGFloat, spec: MAColumnSpec) {
        widths[id] = Swift.min(Swift.max(width, spec.min), spec.max)
    }

    /// “Size to Fit” — double-click a divider. The widest-cell measurement is a
    /// view-layer concern, injected as `contentWidth`.
    public mutating func sizeToFit(_ id: MAColumnID, contentWidth: CGFloat, spec: MAColumnSpec) {
        resize(id, to: contentWidth, spec: spec)
    }

    /// Reconcile a restored layout with the current specs: drop columns that no
    /// longer exist, append newly-declared ones. Keeps autosave compatible as
    /// an app evolves.
    public mutating func reconcile(with specs: [MAColumnSpec]) {
        let ids = Set(specs.map(\.id))
        order.removeAll { !ids.contains($0) }
        for spec in specs where !order.contains(spec.id) {
            order.append(spec.id); widths[spec.id] = spec.ideal
        }
        hidden = hidden.intersection(ids)
    }
}
