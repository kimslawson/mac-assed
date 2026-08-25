//
//  MASortTests.swift  ·  MacAssedCoreTests
//
//  These exercise the UI-free engine — the reason MacAssedCore is split out
//  from the SwiftUI layer. They need no simulator and run on any Swift host,
//  Linux CI included. (Bodies in the shipping types are still sketches; these
//  tests describe the behavior those bodies must satisfy.)
//

import XCTest
@testable import MacAssedCore

private struct File: Identifiable, Sendable {
    let id: Int
    let name: String
    let size: Int
}

final class MASortTests: XCTestCase {

    private let files = [
        File(id: 1, name: "Photo 10.png", size: 300),
        File(id: 2, name: "Photo 2.png",  size: 300),
        File(id: 3, name: "Photo 1.png",  size: 100),
    ]

    func testFinderOrderingIsNumericAware() {
        var sort = MASort<File>()
        sort.setPrimary(.finder("name", "Name", \.name))
        let ordered = files.sorted(by: sort).map(\.name)
        // The whole point: "Photo 2" before "Photo 10", not lexicographically after.
        XCTAssertEqual(ordered, ["Photo 1.png", "Photo 2.png", "Photo 10.png"])
    }

    func testReClickPrimaryFlipsDirection() {
        var sort = MASort<File>()
        sort.setPrimary(.finder("name", "Name", \.name))   // ascending
        sort.setPrimary(.finder("name", "Name", \.name))   // re-click → descending
        let ordered = files.sorted(by: sort).map(\.name)
        XCTAssertEqual(ordered, ["Photo 10.png", "Photo 2.png", "Photo 1.png"])
    }

    func testSecondarySortIsStableTieBreak() {
        var sort = MASort<File>()
        sort.setPrimary(MASortDescriptor("size", "Size", \.size, using: .init()))   // 100,300,300
        sort.addSecondary(.finder("name", "Name", \.name))                          // tie-break by name
        let ordered = files.sorted(by: sort).map(\.name)
        // size asc → the two 300s tie, broken Finder-style by name.
        XCTAssertEqual(ordered, ["Photo 1.png", "Photo 2.png", "Photo 10.png"])
    }
}
