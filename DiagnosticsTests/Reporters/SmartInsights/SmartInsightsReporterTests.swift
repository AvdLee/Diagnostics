//
//  SmartInsightsReporterTests.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 10/02/2022.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import XCTest
@testable import Diagnostics

final class SmartInsightsReporterTests: XCTestCase {

    func testSmartInsightsChapter() async throws {
        let reporter = SmartInsightsReporter()
        let chapter = await reporter.report()
        XCTAssertEqual(chapter.title, "Smart Insights")
        let insightsDictionary = try XCTUnwrap(chapter.diagnostics as? [String: String])
        XCTAssertFalse(insightsDictionary.isEmpty)
    }

    func testRemovingDuplicateInsights() async throws {
        var reporter = SmartInsightsReporter()
        let insight = SmartInsight(name: UUID().uuidString, result: .success(message: UUID().uuidString))

        /// Remove default insights to make this test independent.
        reporter.insights.removeAll()

        reporter.insights.append(contentsOf: [insight, insight, insight])

        let chapter = await reporter.report()
        XCTAssertEqual(chapter.title, "Smart Insights")
        let insightsDictionary = try XCTUnwrap(chapter.diagnostics as? [String: String])
        XCTAssertEqual(insightsDictionary.count, 1, "It should only have one of the custom insights")
    }
}
