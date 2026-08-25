//
//  MAList.swift  ·  MacAssed
//
//  ┌─ API SKETCH ─────────────────────────────────────────────────────────┐
//  │ Design proposal. See docs/Tools.md § MAList.                          │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  Not every list wants columns. `MAList` is the single-column sibling of
//  `MATable`: a plain SwiftUI `List` with the selection grammar, type-select,
//  a sort menu (⌘-click the header chip), and context menus already wired in.
//  It is the smallest step up from `List` that still feels mac-assed — and the
//  right answer on iPhone, where multi-column tables don’t belong.
//
//      MAList(notes, selection: $selection, sortedBy: [.finder("title", "Title", \.title),
//                                                       MASortDescriptor("edited", "Date Edited", \.editedAt, using: .init())]) { note in
//          NoteRow(note)
//      }
//      .typeSelectText(\.title)
//      .rowContextMenu { PinButton($0); DeleteButton($0) }
//

import SwiftUI
import MacAssedCore

public struct MAList<Row: Identifiable & Sendable, RowView: View>: View {
    private let rows: [Row]
    @Binding private var selection: Set<Row.ID>
    private let descriptors: [MASortDescriptor<Row>]
    private let rowView: (Row) -> RowView

    @State private var sort: MASort<Row>

    public init(
        _ rows: [Row],
        selection: Binding<Set<Row.ID>>,
        sortedBy descriptors: [MASortDescriptor<Row>] = [],
        @ViewBuilder row: @escaping (Row) -> RowView
    ) {
        self.rows = rows; self._selection = selection
        self.descriptors = descriptors
        self.rowView = row
        _sort = State(initialValue: MASort(descriptors.isEmpty ? [] : [descriptors[0]]))
    }

    public var body: some View {
        List(selection: $selection) {
            ForEach(rows.sorted(by: sort)) { row in rowView(row) }
        }
        // A compact “Sort ▸” header chip and the ⇧/⌘/marquee grammar attach here
        // via the modifiers in MAModifiers.swift.
    }
}
