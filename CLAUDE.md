# CLAUDE.md — working conventions for MacAssed

Guidance for anyone (human or Claude) writing in this repo.

## Writing style — typography

Prose uses real typographer's characters, never ASCII stand-ins. This applies
to **all prose**: Markdown docs, code comments, doc comments, commit-message
bodies, and any user-facing copy.

- Curly double quotes — `“ ”`, not `"`
- Curly single quotes & apostrophes — `‘ ’`, not `'` (e.g. `it’s`, `SwiftUI’s`)
- Em dash — `—` for parenthetical breaks
- En dash — `–` for numeric and date ranges (e.g. `v0.1–v0.3`, `pp. 3–5`)
- Ellipsis — `…`, not three periods

**Code stays ASCII.** Never curl quotes or substitute dashes inside anything
that is code: Swift string literals and identifiers, Markdown code fences and
inline `` `code` ``, HTML/JS/CSS, URLs, or file paths. Curly quotes in a string
literal or a code fence break the code. The rule is prose-only.

## Library conventions

- **Naming.** Types are `MA`-prefixed UpperCamelCase (`MATable`, `MASort`);
  members are lowerCamelCase (`maTypeSelect` on Apple’s `View`; `columnAutosave`
  on our own `MATable`, no prefix since the type already namespaces it). The
  module is `MacAssed`; the types are `MA…` — the `Foundation`/`NS…` pattern.
  See the README’s “Naming conventions” table. Note: Apple’s MediaAccessibility
  framework also uses `MA` (`MACaptionAppearanceDomain`, …); module-qualification
  avoids clashes, but never reuse a name Apple already ships.
- **Complement, then back-deploy.** Where a MacAssed affordance overlaps a native
  API, defer to the system with `if #available` and fall back to our own below;
  never fork app code on OS version. See DESIGN.md § “Living alongside Apple.”
- **Behavior lives in `MacAssedCore`** — plain, `Sendable`, `Codable`-friendly
  Swift with tests that run on any host (Linux CI included). SwiftUI views stay
  thin and go in `MacAssed`.
- **Defaults are opt-out.** New affordances ship *on* in the flagship controls
  unless there’s a strong reason otherwise.
- **Native by default, nostalgic by choice.** Period looks and spatial mode are
  opt-in; they never change *which* affordances exist.
- **Platform-assed, not Mac-assed everywhere.** Mac is the flagship; iPad is
  first-class *when* a pointer/keyboard is present; iPhone gets only universal
  capabilities in native dress. Never render Mac chrome (clickable headers,
  marquee, a ⌘F bar, Customize Toolbar, spatial canvases) on touch, and never
  replace a native iOS idiom with a Mac one. Gate input-bound affordances on the
  input, not the OS. See DESIGN.md § “Scope.”
- **Accessibility ships with the affordance**, not after it.

## Status

Design sketch / pre-alpha: settled API shapes, illustrative bodies. The
`MacAssedCore` behavior is described by `Tests/MacAssedCoreTests`. The SwiftUI
layer needs an Apple toolchain to build.
