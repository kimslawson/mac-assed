//
//  MACommands.swift  ·  MacAssed
//
//  ┌─ API SKETCH ─────────────────────────────────────────────────────────┐
//  │ Design proposal. See docs/Tools.md § MACommands.                      │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  LOST: menu-bar completeness. A mac-assed app has a View menu with “Sort By
//  ▸”, a real Edit menu (Select All, Invert Selection), and ⌘-equivalents for
//  all of it. SwiftUI makes the menu bar so easy that people ship apps missing
//  half of it.
//
//  FOUND: drop `MACommands()` into your `Scene` and the menus — and their
//  ⌘-keys — appear, wired to whichever MacAssed surface has focus.
//
//      WindowGroup { … }.commands { MACommands() }
//

import SwiftUI

public struct MACommands: Commands {
    public init() {}

    public var body: some Commands {
        // View ▸ Sort By ▸ (fields) / Ascending / Descending / Add Secondary…
        CommandMenu("Sort") { MASortByCommands() }

        // Fill out Edit ▸ with the selection verbs SwiftUI omits.
        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Select All")       { MAFocusAction.selectAll.send() }
                .keyboardShortcut("a", modifiers: .command)
            Button("Invert Selection") { MAFocusAction.invert.send() }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            Button("Deselect All")     { MAFocusAction.deselectAll.send() }
                .keyboardShortcut("a", modifiers: [.command, .shift])
        }

        // View ▸ Columns ▸ (toggles) + Customize…
        CommandGroup(after: .toolbar) { Menu("Columns") { MAColumnVisibilityCommands() } }
    }
}

/// Focused-value plumbing so a menu command reaches the right surface. In a
/// real build these ride SwiftUI `FocusedValues`; sketched here as intents.
enum MAFocusAction: Sendable {
    case selectAll, deselectAll, invert
    func send() { /* forwards to the focused MATable via FocusedValues */ }
}

struct MASortByCommands: View { var body: some View { EmptyView() } }
struct MAColumnVisibilityCommands: View { var body: some View { EmptyView() } }

public extension View {
    /// A ⌘F Find bar that live-filters the collection below it — the classic
    /// slide-down find bar, not a modal sheet. `scopes` recreates the old
    /// scope-bar buttons (“All / Name / Contents”).
    func maFindBar<Scope: Hashable>(
        text: Binding<String>, scopes: [(Scope, String)] = [], scope: Binding<Scope>? = nil
    ) -> some View { modifier(MAFindBar(text: text)) }
}

struct MAFindBar: ViewModifier {
    let text: Binding<String>
    func body(content: Content) -> some View { content /* ⌘F focus + slide-down bar */ }
}
