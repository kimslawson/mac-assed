//
//  MASpatialLayoutTests.swift  ·  MacAssedCoreTests
//
//  Spatial-Finder behavior, as executable expectations — and proof it’s all
//  UI-free: no window, no icon view, runs on any Swift host.
//

import XCTest
@testable import MacAssedCore

final class MASpatialLayoutTests: XCTestCase {

    // Defaults: cell 96, inset 12, columns 6 → slot 0 = (12,12), slot 1 = (108,12).
    private func slot(_ i: Int) -> MAPoint { MAGrid().point(forSlot: i) }

    func testNewItemsTakeTheFirstFreeSlot() {
        var l = MASpatialLayout()
        l.place("a"); l.place("b")
        XCTAssertEqual(l.positions["a"], slot(0))
        XCTAssertEqual(l.positions["b"], slot(1))
    }

    func testPlacementNeverDisturbsHandPlacedIcons() {
        var l = MASpatialLayout(positions: ["a": slot(2)])   // user dragged “a” to slot 2
        l.place("c")                                          // a new file appears
        XCTAssertEqual(l.positions["a"], slot(2))             // untouched
        XCTAssertEqual(l.positions["c"], slot(0))             // fills the first gap
    }

    func testCleanUpSnapsToNearestGridSlot() {
        var l = MASpatialLayout(positions: ["a": MAPoint(x: 130, y: 40)])
        l.cleanUp()
        XCTAssertEqual(l.positions["a"], slot(1))             // nearest slot origin
    }

    func testArrangeReflowsSortedOrderAndIsUndoable() {
        var l = MASpatialLayout(positions: ["a": slot(5), "b": slot(3)])
        let before = l.positions
        l.arrange(order: ["b", "a"])                          // caller sorted; b first
        XCTAssertEqual(l.positions["b"], slot(0))
        XCTAssertEqual(l.positions["a"], slot(1))
        XCTAssertTrue(l.restoreSnapshot())                    // Reset Layout
        XCTAssertEqual(l.positions, before)                  // hand-placed layout is back
        XCTAssertFalse(l.restoreSnapshot())                  // nothing left to restore
    }
}
