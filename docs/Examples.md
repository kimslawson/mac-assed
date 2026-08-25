# Examples

*Evidence that this was, in fact, possible.*

Worked snippets, smallest to largest. All are **API sketches** against the
shapes in [Tools.md](Tools.md) — they show intended call sites, not a shipping
build yet.

---

## 1 · The 30-second upgrade

You have a `List`. You want it to sort like a Mac and select like a Mac. One
type, one string:

```swift
// Before — a plain, austere SwiftUI list.
List(files, selection: $selection) { file in
    Text(file.name)
}

// After — sortable columns, ⇧/⌘ selection, type-select, keyboard nav, autosave.
MATable(files, selection: $selection) {
    MAColumn("Name", value: \.name)
    MAColumn("Size", value: \.size, align: .trailing)
}
.columnAutosave("Files")
```

That diff is the whole pitch.

---

## 2 · Adopting one behavior at a time

Can't swap the list wholesale? Graft the single thing you miss most. Nothing
else changes.

```swift
List(people, selection: $selection) { PersonRow($0) }
    .maTypeSelect(people, id: \.id, text: \.lastName, selection: $selection)
```

Now typing "sla" jumps to *Slawson*. Ship it Tuesday; do the rest never.

---

## 3 · A real Inbox

Multi-column, compound sort, selection-aware batch actions, a live status bar,
and a window that comes back exactly how you left it.

```swift
struct InboxView: View {
    @State private var selection: Set<Message.ID> = []
    let messages: [Message]

    var body: some View {
        MATable(messages, selection: $selection) {
            MAColumn("", value: \.isRead) { Circle().fill($0.isRead ? .clear : .blue).frame(width: 8) }
                .width(min: 16, ideal: 16, max: 16)
            MAColumn("From",     value: \.sender)
            MAColumn("Subject",  value: \.subject)
            MAColumn("Received", value: \.date) { Text($0.date, format: .relative(presentation: .named)) }
                .width(ideal: 140)
            MAColumn("Size",     value: \.size, align: .trailing).width(min: 64, ideal: 80)
        }
        .columnAutosave("Inbox")
        .rowContextMenu { ids in
            Button("Reply")   { reply(to: ids) }
            Button("Archive \(ids.count) Messages") { archive(ids) }
            Divider()
            Button("Delete", role: .destructive) { delete(ids) }
        }
        .tableStatusBar()
    }
}
```

Restores, in one view: Finder sort · secondary sort (⌥-click *From* after
*Received*) · ⇧/⌘/marquee selection · type-select on *From* · ⌘A/Invert from the
menu bar · column resize/reorder/hide · autosaved widths **and** sort ·
"Archive 3 Messages" that respects the selection · the count in the corner.

---

## 4 · A Finder-style browser (outline + inspector)

```swift
NavigationSplitView {
    MASidebar(selection: $sidebarItem) { … }             // §12
} content: {
    MAOutline(tree, selection: $selection,               // §7 disclosure + expand-all
              children: \.children) { NodeRow($0) }
        .maContextMenu(selection: $selection) { ids in    // §5 selection-aware
            Button("Get Info") { showInfo(ids) }
            Button("Reveal in Finder") { reveal(ids) }
        }
        .maQuickLook(selection) { url(for: $0) }          // §6 Space to preview
} detail: {
    MAInspector(selection: selection)                     // §11 multi-value "Get Info"
}
.maFindBar(text: $query)                                  // §8 ⌘F live filter
```

*(`MASidebar`, `MAOutline`, `MAInspector` are roadmap — shown here so the shape
of a fully mac-assed window is legible.)*

---

## 5 · Just the engine, in a test

The behavior is plain Swift. No view, no simulator — this runs on Linux CI:

```swift
import MacAssedCore
import XCTest

func testInboxSortsLikeAMac() {
    var sort = MASort<Message>()
    sort.setPrimary(.finder("subject", "Subject", \.subject))
    let subjects = inbox.sorted(by: sort).map(\.subject)
    XCTAssertEqual(subjects.first, "Re: Photo 2.png")   // …before "Re: Photo 10.png"
}
```

That separation — testable behavior under swappable views — is the point of the
[two-module architecture](../DESIGN.md#architecture).

---

## Want to contribute an example?

Real apps make the best evidence. A screenshot + the view that produced it is
the ideal [pull request](../CONTRIBUTING.md).
