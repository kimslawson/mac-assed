//
//  MASelectionTests.swift  ·  MacAssedCoreTests
//
//  The selection grammar, described as executable expectations.
//

import XCTest
@testable import MacAssedCore

final class MASelectionTests: XCTestCase {

    private func fresh() -> MASelection<Int> { MASelection(orderedIDs: [1, 2, 3, 4, 5]) }

    func testClickSetsSingleSelectionAndAnchor() {
        var sel = fresh()
        sel.select(3)
        XCTAssertEqual(sel.selected, [3])
        XCTAssertEqual(sel.anchor, 3)
    }

    func testShiftClickExtendsRangeFromAnchor() {
        var sel = fresh()
        sel.select(2)
        sel.extend(to: 5)                 // ⇧-click
        XCTAssertEqual(sel.selected, [2, 3, 4, 5])
        XCTAssertEqual(sel.anchor, 2)     // anchor pivots, doesn't move
    }

    func testAdditiveExtendPreservesDiscontiguousIslands() {
        var sel = fresh()
        sel.select(1)
        sel.toggle(3)                     // ⌘-click → {1,3}
        sel.extend(to: 5, additive: true) // ⌘⇧-click from anchor 3 → adds 3,4,5
        XCTAssertEqual(sel.selected, [1, 3, 4, 5])
    }

    func testInvert() {
        var sel = fresh()
        sel.select(2)
        sel.toggle(4)                     // {2,4}
        sel.invert()                      // {1,3,5}
        XCTAssertEqual(sel.selected, [1, 3, 5])
    }

    func testArrowDownExtendingGrowsFromCurrent() {
        var sel = fresh()
        sel.select(2)
        sel.move(.down, extending: true)  // ⇧↓
        XCTAssertEqual(sel.selected, [2, 3])
    }

    func testRangeMathFollowsVisibleOrderNotIDOrder() {
        // After a re-sort the visible order changes; range selection must honor it.
        var sel = MASelection(orderedIDs: [5, 4, 3, 2, 1])
        sel.select(5)
        sel.extend(to: 3)                 // visible positions 0…2
        XCTAssertEqual(sel.selected, [5, 4, 3])
    }
}
