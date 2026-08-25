# Contributing to MacAssed

MacAssed is meant to be a community foundation — a Lost & Found that grows as
people notice what's missing. There are three especially useful ways in.

## 1 · File a Lost & Found claim ticket

Miss an affordance that isn't in [the catalog](docs/Lost-and-Found.md)? Open an
issue titled **"Lost & Found: <the thing>"** and include:

- **What it was** — the classic behavior, ideally with the app that did it well.
- **Where SwiftUI left it** — genuinely gone (🔦) or present-but-crippled (🥾)?
- **The task that got harder** without it. (The bar isn't "it's old." It's "a
  real task regressed.")

## 2 · Claim a roadmap tool

The [roadmap](DESIGN.md#roadmap) lists tools that are sketched but unbuilt
(`MAOutline`, `MADrag`, `MAInspector`, …). Comment on its tracking issue to
claim one. The design shape is already in [Tools.md](docs/Tools.md); the job is
to make the body real.

## 3 · Contribute evidence

A screenshot of a real app using MacAssed, plus the view that produced it, is
the best possible addition to [Examples.md](docs/Examples.md).

## Working agreements

- **Behavior goes in `MacAssedCore`**, as `Sendable`, `Codable`-friendly, plain
  Swift with tests that run on Linux. Views stay thin.
- **Defaults are opt-out.** A new affordance ships *on* in the flagship controls
  unless there's a strong reason it shouldn't.
- **Native by default; nostalgia is opt-in** and lives in `MAChrome`.
- **Accessibility ships with the affordance**, not after it — keyboard
  operability and VoiceOver traits are part of "done."
- **Match the platform's grain.** Prefer reusing `SortComparator`, `KeyPath`,
  `@Observable`, and result builders over inventing parallel machinery.

## Building

`MacAssedCore` builds and tests with a stock Swift toolchain:

```sh
swift test            # runs MacAssedCoreTests (no simulator needed)
```

The `MacAssed` SwiftUI target requires an Apple platform (Xcode / a macOS host).

---

*By contributing you agree your work is licensed under the project's MIT
license.*
