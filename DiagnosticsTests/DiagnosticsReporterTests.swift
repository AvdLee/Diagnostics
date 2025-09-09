//
//  DiagnosticsReporterTests.swift
//  DiagnosticsTests
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import XCTest
@testable import Diagnostics

final class DiagnosticsReporterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        try! DiagnosticsLogger.setup()
    }

    override func tearDown() {
        try! DiagnosticsLogger.standard.deleteLogs()
        super.tearDown()
    }

    /// It should correctly generate HTML from the reporters.
    func testHTMLGeneration() async throws {
        let diagnosticsChapter = DiagnosticsChapter(title: UUID().uuidString, diagnostics: UUID().uuidString)
        var reporter = MockedReporter()
        reporter.diagnosticsChapter = diagnosticsChapter
        let reporters = [reporter]
        let report = await DiagnosticsReporter.create(using: reporters)
        let html = String(data: report.data, encoding: .utf8)!

        XCTAssertTrue(html.contains("<h3>\(diagnosticsChapter.title)</h3>"))
        XCTAssertTrue(html.contains(diagnosticsChapter.diagnostics as! String))
    }

    /// It should create a chapter for each reporter.
    func testReportingChapters() async throws {
        let report = await DiagnosticsReporter.create()
        let html = String(data: report.data, encoding: .utf8)!
        let expectedChaptersCount = DiagnosticsReporter.DefaultReporter.allCases.count
        let chaptersCount = html.components(separatedBy: "<div class=\"chapter\"").count - 1
        XCTAssertEqual(expectedChaptersCount, chaptersCount)
    }

    /// It should filter using passed filters.
    func testFilters() async throws {
        let keyToFilter = UUID().uuidString
        let mockedReport = MockedReport(diagnostics: [keyToFilter: UUID().uuidString])
        let report = await DiagnosticsReporter.create(using: [mockedReport], filters: [MockedFilter.self])
        let html = String(data: report.data, encoding: .utf8)!
        XCTAssertFalse(html.contains(keyToFilter))
        XCTAssertTrue(html.contains("FILTERED"))
    }

    func testWithoutProvidingSmartInsightsProvider() async throws {
        let mockedReport = MockedReport(diagnostics: ["key": UUID().uuidString])
        let report = await DiagnosticsReporter.create(using: [mockedReport, SmartInsightsReporter()], filters: [MockedFilter.self], smartInsightsProvider: nil)
        let html = String(data: report.data, encoding: .utf8)!
        XCTAssertTrue(html.contains("Smart Insights"), "Default insights should still be added")
    }

    func testWithSmartInsightsProviderReturningNoExtraInsights() async throws {
        let mockedReport = MockedReport(diagnostics: ["key": UUID().uuidString])
        let report = await DiagnosticsReporter.create(using: [mockedReport, SmartInsightsReporter()], filters: [MockedFilter.self], smartInsightsProvider: MockedInsightsProvider(insightToReturn: nil))
        let html = String(data: report.data, encoding: .utf8)!
        XCTAssertTrue(html.contains("Smart Insights"), "Default insights should still be added")
    }

    func testWithSmartInsightsProviderReturningExtraInsights() async throws {
        let mockedReport = MockedReport(diagnostics: ["key": UUID().uuidString])
        let insightToReturn = SmartInsight(name: UUID().uuidString, result: .success(message: UUID().uuidString))
        let report = await DiagnosticsReporter.create(using: [mockedReport, SmartInsightsReporter()], filters: [MockedFilter.self], smartInsightsProvider: MockedInsightsProvider(insightToReturn: insightToReturn))
        let html = String(data: report.data, encoding: .utf8)!
        XCTAssertTrue(html.contains(insightToReturn.name))
        XCTAssertTrue(html.contains(insightToReturn.result.message))
    }

    /// It should correctly generate the header.
    func testHeaderGeneration() async throws {
        let report = await DiagnosticsReporter.create(using: [])
        let html = String(data: report.data, encoding: .utf8)!

        XCTAssertTrue(html.contains("<head>"))
        XCTAssertTrue(html.contains("<title>xctest - Diagnostics Report</title>"))
        XCTAssertTrue(html.contains(DiagnosticsReporter.style()))
        XCTAssertTrue(html.contains("</head>"))
    }
}

struct MockedReport: DiagnosticsReporting {
    var diagnostics: Diagnostics = [String: String]()
    func report() -> DiagnosticsChapter {
        return DiagnosticsChapter(title: UUID().uuidString, diagnostics: diagnostics)
    }
}

struct MockedFilter: DiagnosticsReportFilter {
    static func filter(_ diagnostics: Diagnostics) -> Diagnostics {
        return "FILTERED"
    }
}

struct MockedInsightsProvider: SmartInsightsProviding {
    let insightToReturn: SmartInsightProviding?

    func smartInsights(for chapter: DiagnosticsChapter) -> [SmartInsightProviding] {
        guard let insightToReturn = insightToReturn else {
            return []
        }

        return [insightToReturn]
    }
}
