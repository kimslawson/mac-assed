//
//  MATable.swift  ·  MacAssed
//
//  ┌─ API SKETCH ─────────────────────────────────────────────────────────┐
//  │ Design proposal for the flagship view. Bodies are illustrative — the  │
//  │ point is the *shape*. See docs/Tools.md § MATable.                     │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  The one-screenful pitch: a sortable, multi-select, column-managed, self-
//  persisting table that is one type name and one autosave string away from a
//  plain SwiftUI list.
//
//      MATable(inbox, selection: $selection) {
//          MAColumn("Name",     value: \.name)                 // Finder-sorted, type-select target
//          MAColumn("From",     value: \.sender)
//          MAColumn("Received", value: \.date) { Text($0.date, format: .relative(presentation: .named)) }
//          MAColumn("Size",     value: \.size, align: .trailing).width(min: 64, ideal: 80)
//      }
//      .columnAutosave("Inbox")     // widths · order · visibility · sort, remembered forever
//      .rowContextMenu { rows in ReplyButton(rows); ArchiveButton(rows) }
//      .tableStatusBar()            // "1,204 messages, 3 selected"
//
//  ⇧-range, ⌘-toggle, marquee, ⌘A, type-select, ⌥-click secondary sort, and
//  “Copy as TSV” are ON by default — because that is what mac-assed means. You
//  opt *out*, not in.
//

import SwiftUI
import MacAssedCore

/// A drop-in upgrade over SwiftUI’s `Table`/`List` restoring the classic Mac
/// list affordances. Full-strength on macOS and iPad; degrades sensibly on iOS
/// (see the platform matrix in DESIGN.md).
public struct MATable<Row: Identifiable & Sendable>: View {

    private let rows: [Row]
    @Binding private var selection: Set<Row.ID>
    private let columns: [MAColumn<Row>]

    @State private var sort = MASort<Row>()
    @State private var layout = MAColumnLayout()

    var autosaveName: String?
    var style: MATableStyle = .automatic
    var showsStatusBar = false
    var rowMenu: (@Sendable (Set<Row.ID>) -> AnyView)?

    public init(
        _ rows: [Row],
        selection: Binding<Set<Row.ID>>,
        @MAColumnBuilder<Row> columns: () -> [MAColumn<Row>]
    ) {
        self.rows = rows; self._selection = selection; self.columns = columns()
    }

    public var body: some View {
        // Illustrative composition. Production backs this with an NSTableView
        // representable on macOS (pixel-true headers, free type-select) and a
        // Table/List on iPad/iOS. The public API is identical either way.
        VStack(spacing: 0) {
            MAColumnHeader(specs: columns.map(\.spec), layout: $layout, sort: $sort)
            MASortedBody(rows: rows.sorted(by: sort), columns: columns,
                         layout: layout, selection: $selection)
            if showsStatusBar { MAStatusBar(total: rows.count, selected: selection.count) }
        }
        .task(id: autosaveName) { restore() }
    }

    private func restore() {
        guard let name = autosaveName else { layout = .default(from: columns.map(\.spec)); return }
        let store = MAUserDefaultsStore(autosaveName: name)
        if var l = store.load(MAColumnLayout.self, for: MAViewStateKey.columns) {
            l.reconcile(with: columns.map(\.spec)); layout = l
        } else {
            layout = .default(from: columns.map(\.spec))
        }
        // …plus sort restore, and a sink writing changes straight back to `store`.
    }
}

// MARK: - MAColumn

/// One column. Sortable, resizable, hideable — unless you say otherwise.
public struct MAColumn<Row>: Sendable {
    let spec: MAColumnSpec
    let content: @Sendable (Row) -> AnyView
    let sortDescriptor: MASortDescriptor<Row>?
    let typeSelectText: (@Sendable (Row) -> String)?

    /// Value-keyed `String` column: default cell + Finder-style sort + eligible
    /// type-select target, for free.
    public init(
        _ title: String, value keyPath: KeyPath<Row, String> & Sendable,
        align: MAColumnSpec.Alignment = .leading
    ) {
        self.spec = MAColumnSpec(title.maColumnID, title: title, alignment: align)
        self.content = { AnyView(Text($0[keyPath: keyPath])) }
        self.sortDescriptor = .finder(title.maColumnID, title, keyPath)
        self.typeSelectText = { $0[keyPath: keyPath] }
    }

    /// Custom-cell column over any `Comparable` value.
    public init<Value: Comparable & Sendable>(
        _ title: String, value keyPath: KeyPath<Row, Value> & Sendable,
        align: MAColumnSpec.Alignment = .leading,
        @ViewBuilder cell: @escaping @Sendable (Row) -> some View
    ) {
        self.spec = MAColumnSpec(title.maColumnID, title: title, alignment: align)
        self.content = { AnyView(cell($0)) }
        self.sortDescriptor = MASortDescriptor(title.maColumnID, title, keyPath, using: .init())
        self.typeSelectText = nil
    }

    /// Width constraints, mirroring `TableColumn.width(min:ideal:max:)`.
    public func width(min: CGFloat? = nil, ideal: CGFloat? = nil, max: CGFloat? = nil) -> Self {
        var s = spec
        if let min { s.min = min }; if let ideal { s.ideal = ideal }; if let max { s.max = max }
        return MAColumn(spec: s, content: content, sortDescriptor: sortDescriptor, typeSelectText: typeSelectText)
    }

    init(spec: MAColumnSpec, content: @escaping @Sendable (Row) -> AnyView,
         sortDescriptor: MASortDescriptor<Row>?, typeSelectText: (@Sendable (Row) -> String)?) {
        self.spec = spec; self.content = content
        self.sortDescriptor = sortDescriptor; self.typeSelectText = typeSelectText
    }
}

@resultBuilder
public enum MAColumnBuilder<Row> {
    public static func buildBlock(_ parts: MAColumn<Row>...) -> [MAColumn<Row>] { parts }
    public static func buildOptional(_ part: [MAColumn<Row>]?) -> [MAColumn<Row>] { part ?? [] }
    public static func buildEither(first: [MAColumn<Row>]) -> [MAColumn<Row>] { first }
    public static func buildEither(second: [MAColumn<Row>]) -> [MAColumn<Row>] { second }
}

private extension String {
    var maColumnID: MAColumnID { lowercased().replacingOccurrences(of: " ", with: "_") }
}

// MARK: - Fluent configuration

public extension MATable {
    /// Remember widths, order, visibility, and sort under this name — forever,
    /// per user. The whole point.
    func columnAutosave(_ name: String) -> Self { var c = self; c.autosaveName = name; return c }

    /// Right-click / long-press menu whose commands receive the *current
    /// selection*, so batch actions Just Work.
    func rowContextMenu(@ViewBuilder _ menu: @escaping @Sendable (Set<Row.ID>) -> some View) -> Self {
        var c = self; c.rowMenu = { AnyView(menu($0)) }; return c
    }

    /// The classic bottom-of-window item count. Off by default; one call on.
    func tableStatusBar() -> Self { var c = self; c.showsStatusBar = true; return c }

    func tableStyle(_ style: MATableStyle) -> Self { var c = self; c.style = style; return c }
}

/// Table look. `.automatic` follows the platform; classic skins live in MAChrome.
public enum MATableStyle: Sendable { case automatic, plain, insetAlternating, classicAqua }

// Illustrative shells — real bodies live in sibling files / the AppKit bridge.
struct MAColumnHeader<Row>: View { let specs: [MAColumnSpec]; @Binding var layout: MAColumnLayout; @Binding var sort: MASort<Row>; var body: some View { EmptyView() } }
struct MASortedBody<Row: Identifiable>: View { let rows: [Row]; let columns: [MAColumn<Row>]; let layout: MAColumnLayout; @Binding var selection: Set<Row.ID>; var body: some View { EmptyView() } }
struct MAStatusBar: View { let total: Int; let selected: Int; var body: some View { EmptyView() } }
