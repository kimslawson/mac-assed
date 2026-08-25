//
//  MAChrome.swift  ·  MacAssed
//
//  ┌─ API SKETCH ─────────────────────────────────────────────────────────┐
//  │ Design proposal. See docs/Tools.md § MAChrome and                     │
//  │ docs/Lost-and-Found.md § "The look".                                  │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  Everything else in MacAssed restores *behavior* and defaults to native
//  looks. MAChrome is the opt-in *nostalgia* layer — tasteful, switchable
//  visual skins that recall the eras, for people who want them. Off by default,
//  never kitsch, always driven by the same tokens so a skin can't break layout.
//
//      MATable(…) { … }.maChrome(.platinum)   // Mac OS 8/9 grayscale gradients
//      MATable(…) { … }.maChrome(.aqua)       // early Mac OS X pinstripes & gel
//      MATable(…) { … }.maChrome(.system)     // default — today's native look
//
//  The point isn't skeuomorphism for its own sake. It's that the *affordances*
//  a skin implies (a header that clearly looks clickable, a divider that
//  clearly looks draggable) came free with those looks and got flattened away.
//

import SwiftUI

/// A switchable visual identity. `.system` is the default and the one to ship;
/// the period skins are for hobby apps, demos, and people who miss it.
public enum MAChromeStyle: String, CaseIterable, Sendable, Identifiable {
    case system     // today's native look — the default
    case platinum   // Mac OS 8/9 Platinum: grayscale gradients, chiseled dividers
    case aqua       // early Mac OS X Aqua: pinstripes, gel buttons, lickable scrollers
    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system:   "System (Default)"
        case .platinum: "Platinum"
        case .aqua:     "Aqua"
        }
    }
}

public extension View {
    /// Apply a MacAssed chrome skin to everything inside. Skins only restyle;
    /// they never change which affordances exist.
    func maChrome(_ style: MAChromeStyle) -> some View {
        environment(\.maChrome, style)
    }
}

private struct MAChromeKey: EnvironmentKey { static let defaultValue: MAChromeStyle = .system }
public extension EnvironmentValues {
    var maChrome: MAChromeStyle {
        get { self[MAChromeKey.self] } set { self[MAChromeKey.self] = newValue }
    }
}
