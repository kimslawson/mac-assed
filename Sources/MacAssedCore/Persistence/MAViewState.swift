//
//  MAViewState.swift  ·  MacAssedCore
//
//  ┌─ API SKETCH ─────────────────────────────────────────────────────────┐
//  │ Design proposal. See docs/Tools.md § MAViewState.                     │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  LOST: `autosaveName`. In AppKit you handed a view a string and it quietly
//  remembered its column widths, sort order, sidebar width, expanded rows, and
//  window frame — forever, per user, no code. The app just came back the way
//  you left it.
//
//  SwiftUI has `@AppStorage`/`@SceneStorage` for primitives but no convention
//  for the compound state a real document window carries.
//
//  FOUND: `MAViewStateStore` — one autosave name, one `Codable` blob, pluggable
//  backing (UserDefaults today; SwiftData/iCloud tomorrow).
//

import Foundation

/// A namespaced, `Codable` key/value store keyed by an autosave name. One
/// instance owns one window/scene’s remembered state.
public protocol MAViewStateStore: Sendable {
    func load<T: Codable>(_ type: T.Type, for key: String) -> T?
    func save<T: Codable>(_ value: T, for key: String)
    func clear(for key: String)
}

/// Default backing: JSON in `UserDefaults` under a `MacAssed.<name>.` prefix —
/// human-readable, `defaults read`-able, trivial to migrate.
public struct MAUserDefaultsStore: MAViewStateStore {
    public let autosaveName: String
    private let defaults: UserDefaults

    public init(autosaveName: String, defaults: UserDefaults = .standard) {
        self.autosaveName = autosaveName; self.defaults = defaults
    }

    private func key(_ k: String) -> String { "MacAssed.\(autosaveName).\(k)" }

    public func load<T: Codable>(_ type: T.Type, for k: String) -> T? {
        guard let data = defaults.data(forKey: key(k)) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    public func save<T: Codable>(_ value: T, for k: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key(k))
    }
    public func clear(for k: String) { defaults.removeObject(forKey: key(k)) }
}

/// The compound state a mac-assed window remembers between launches. Everything
/// optional, so partial adoption persists exactly what you use and nothing else.
public struct MAWindowState: Codable, Equatable, Sendable {
    public var columns: MAColumnLayout?
    public var sort: MASortState?
    public var expandedRows: Set<String>?     // outline disclosure
    public var sidebarWidth: Double?
    public var windowFrame: Frame?
    public var selection: Set<String>?        // opt-in; some apps find restore surprising

    public struct Frame: Codable, Equatable, Sendable { public var x, y, width, height: Double }
    public init() {}
}

/// Well-known keys so an app (or MacAssed) can read/write pieces without
/// stomping neighbors — the granularity AppKit autosave had.
public enum MAViewStateKey {
    public static let columns   = "columns"
    public static let sort      = "sort"
    public static let expanded  = "expandedRows"
    public static let sidebar   = "sidebarWidth"
    public static let frame     = "windowFrame"
    public static let selection = "selection"
}
