//
//  MAAvailability.swift  ·  MacAssed
//
//  ┌─ API SKETCH ─────────────────────────────────────────────────────────┐
//  │ Design proposal. See DESIGN.md § “Living alongside Apple”. Bodies      │
//  │ illustrative — the point is the compatibility *pattern*.               │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  The polyfill pattern MacAssed uses everywhere it overlaps a native API:
//  expose ONE stable `MA` call, defer to the system implementation where the OS
//  has it (`if #available`), and fall back to MacAssed’s own below. App code
//  never branches on OS version or platform — the library absorbs that.
//
//  Two worked examples:
//    • `maReorder`      — “polyfill, defer when native”. Apple shipped
//                         `.reorderable` in the 27 releases; below that we run
//                         our own back-deployed reorder.
//    • `maMoveCommand`  — “availability-gap smoother”. `.onMoveCommand` exists on
//                         macOS/tvOS but not iOS/iPadOS, so we use it where it is
//                         and `.onKeyPress` where it isn’t.
//
//  Reminder on the two levers (see DESIGN.md for the full note):
//    • compile-time (`#if os(...)`, `#if canImport(...)`) decides what compiles;
//    • runtime (`if #available(macOS 27, *)`) decides what runs — the polyfill
//      lever. There is no compile-time “target OS ≥ 27” and no `PATH` probe;
//      availability is an OS-version question resolved at runtime.
//

import SwiftUI

// MARK: - Defer-when-native: reordering

public extension View {
    /// Drag-to-reorder, one call across every supported OS.
    ///
    /// On the 27 releases this defers to Apple’s `.reorderable` /
    /// `.reorderContainer(for:)` — you inherit its polish, accessibility, and
    /// future fixes. Below that, MacAssed supplies the behavior itself. Your call
    /// site is identical either way.
    @ViewBuilder
    func maReorder<Element: Sendable>(_ items: Binding<[Element]>) -> some View {
        if #available(macOS 27, iOS 27, *) {
            // Native path: self.reorderable() + .reorderContainer(for: Element.self) { … }
            self
        } else {
            // Back-deployed path: MacAssed’s own drag-to-reorder for macOS 14–26.
            modifier(MABackDeployedReorder(items: items))
        }
    }
}

// MARK: - Gap-smoother: arrow-key “move” intent

/// Intent, not keystrokes — “the user wants to move down,” regardless of which
/// key or platform expressed it. (Andrade’s point: `.onMoveCommand` deals in
/// intent; `.onKeyPress` deals in keys. We prefer intent where the OS offers it.)
public enum MAMoveDirection: Sendable { case up, down, left, right }

public extension View {
    /// Arrow-key move intent that works the same on macOS, iPadOS, and iOS,
    /// smoothing over `.onMoveCommand` being unavailable on iOS/iPadOS.
    func maMoveCommand(_ perform: @escaping (MAMoveDirection) -> Void) -> some View {
        #if os(iOS)
        // iOS/iPadOS: no `.onMoveCommand`, so translate arrow key presses.
        return modifier(MAKeyPressMove(perform: perform))
        #else
        // macOS/tvOS: the native intent-level API.
        return onMoveCommand { direction in
            perform(MAMoveDirection(direction))
        }
        #endif
    }
}

#if !os(iOS)
private extension MAMoveDirection {
    init(_ d: MoveCommandDirection) {
        switch d {
        case .up:    self = .up
        case .down:  self = .down
        case .left:  self = .left
        case .right: self = .right
        @unknown default: self = .down
        }
    }
}
#endif

// Illustrative fallback modifiers — bodies live with the real implementations.
struct MABackDeployedReorder<Element>: ViewModifier {
    let items: Binding<[Element]>
    func body(content: Content) -> some View { content }   // MacAssed drag-to-reorder
}
struct MAKeyPressMove: ViewModifier {
    let perform: (MAMoveDirection) -> Void
    func body(content: Content) -> some View { content }   // .onKeyPress(.upArrow / .downArrow …)
}
