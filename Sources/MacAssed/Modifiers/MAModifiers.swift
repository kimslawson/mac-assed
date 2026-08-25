//
//  MAModifiers.swift  ·  MacAssed
//
//  ┌─ API SKETCH ─────────────────────────────────────────────────────────┐
//  │ Design proposal. See docs/Tools.md § “Grafting modifiers” and         │
//  │ docs/Examples.md § “Adopting one behavior at a time”.                 │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  Not everyone can throw out their `List`. These modifiers *graft* individual
//  affordances onto the SwiftUI views you already ship — one behavior on a
//  Tuesday, no rewrite. Each is independent.
//

import SwiftUI
import MacAssedCore

public extension View {

    /// Type-select: start typing and the list jumps to the first row whose
    /// `text` matches, with a short reset timeout — the single most muscle-
    /// memory’d Finder behavior SwiftUI dropped.
    ///
    ///     List(files, selection: $sel) { … }
    ///         .maTypeSelect(files, id: \.id, text: \.name, selection: $sel)
    func maTypeSelect<Row, ID: Hashable>(
        _ rows: [Row], id: KeyPath<Row, ID>,
        text: @escaping (Row) -> String,
        selection: Binding<Set<ID>>
    ) -> some View {
        modifier(MATypeSelect(rows: rows, id: id, text: text, selection: selection))
    }

    /// The full pointer selection grammar (⇧-range, ⌘-toggle, marquee, invert)
    /// for a custom collection that only has a `Set<ID>` binding today.
    func maSelection<ID: Hashable & Sendable>(
        _ selection: Binding<Set<ID>>, orderedIDs: [ID]
    ) -> some View {
        modifier(MASelectionGrammar(selection: selection, orderedIDs: orderedIDs))
    }

    /// Spacebar Quick Look for the current selection — the Finder gesture, on
    /// anything that can vend a file URL.
    func maQuickLook<ID: Hashable>(_ selection: Set<ID>, url: @escaping (ID) -> URL?) -> some View {
        modifier(MAQuickLook(ids: Array(selection), url: url))
    }

    /// ⌘C that yields tab-separated rows — so a copy out of your table pastes
    /// straight into Numbers or a spreadsheet, the way a real list always could.
    func maCopyAsTSV<Row>(_ rows: [Row], columns: [(String, (Row) -> String)]) -> some View {
        modifier(MATSVCopy(rows: rows, columns: columns))
    }

    /// User-customizable toolbar — the classic “Customize Toolbar…” sheet with
    /// drag-in/out items and icon/label modes, persisted under `id`. SwiftUI
    /// toolbars aren’t user-arrangeable; this brings that back.
    func maCustomizableToolbar(id: String) -> some View {
        modifier(MACustomizableToolbar(autosaveID: id))
    }
}

// Illustrative modifier shells — bodies elided in this sketch. Each wraps a
// MacAssedCore model (MASelection, MASort) and translates SwiftUI gestures.
struct MATypeSelect<Row, ID: Hashable>: ViewModifier {
    let rows: [Row]; let id: KeyPath<Row, ID>
    let text: (Row) -> String; let selection: Binding<Set<ID>>
    func body(content: Content) -> some View { content /* .onKeyPress → jump */ }
}
struct MASelectionGrammar<ID: Hashable & Sendable>: ViewModifier {
    let selection: Binding<Set<ID>>; let orderedIDs: [ID]
    func body(content: Content) -> some View { content /* feeds MASelection<ID> */ }
}
struct MAQuickLook<ID: Hashable>: ViewModifier {
    let ids: [ID]; let url: (ID) -> URL?
    func body(content: Content) -> some View { content }
}
struct MATSVCopy<Row>: ViewModifier {
    let rows: [Row]; let columns: [(String, (Row) -> String)]
    func body(content: Content) -> some View { content }
}
struct MACustomizableToolbar: ViewModifier {
    let autosaveID: String
    func body(content: Content) -> some View { content }
}
