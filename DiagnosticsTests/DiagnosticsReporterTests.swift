//
//  DiagnosticsReporterTests.swift
//  DiagnosticsTests
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
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
        let document = try XCTUnwrap(html.diagnosticsReportDocument)

        XCTAssertEqual(report.filename, "Diagnostics-Report.html")
        XCTAssertEqual(report.mimeType, .html)
        XCTAssertTrue(html.contains("<script id=\"diagnostics-report-data\" type=\"application/json\">"))
        XCTAssertTrue(html.contains("<main id=\"diagnostics-report\" class=\"container\"></main>"))
        XCTAssertEqual(document.chapters.first?.title, diagnosticsChapter.title)
        if case .text(let value)? = document.chapters.first?.data {
            XCTAssertEqual(value, diagnosticsChapter.diagnostics as! String)
        } else {
            XCTFail("Expected text diagnostics")
        }
    }

    func testJSONGeneration() async throws {
        let diagnosticsChapter = DiagnosticsChapter(title: UUID().uuidString, diagnostics: UUID().uuidString)
        var reporter = MockedReporter()
        reporter.diagnosticsChapter = diagnosticsChapter
        let reporters = [reporter]
        let report = await DiagnosticsReporter.create(format: .json, using: reporters)
        let document = try JSONDecoder().decode(DiagnosticsReportDocument.self, from: report.data)

        XCTAssertEqual(report.filename, "Diagnostics-Report.json")
        XCTAssertEqual(report.mimeType, .json)
        XCTAssertEqual(document.chapters.first?.title, diagnosticsChapter.title)
        if case .text(let value)? = document.chapters.first?.data {
            XCTAssertEqual(value, diagnosticsChapter.diagnostics as! String)
        } else {
            XCTFail("Expected text diagnostics")
        }
    }

    /// It should create a chapter for each reporter.
    func testReportingChapters() async throws {
        let report = await DiagnosticsReporter.create()
        let html = String(data: report.data, encoding: .utf8)!
        let document = try XCTUnwrap(html.diagnosticsReportDocument)
        let expectedChaptersCount = DiagnosticsReporter.DefaultReporter.allCases.count
        XCTAssertEqual(expectedChaptersCount, document.chapters.count)
    }

    func testGeneralInfoPreservesFormattedHTMLAndHiddenTitle() async throws {
        let report = await DiagnosticsReporter.create(using: [GeneralInfoReporter()])
        let html = String(data: report.data, encoding: .utf8)!
        let document = try XCTUnwrap(html.diagnosticsReportDocument)
        let chapter = try XCTUnwrap(document.chapters.first)

        XCTAssertFalse(chapter.showTitle)
        XCTAssertTrue(chapter.legacyHTML?.contains("<p>This diagnostics report can help") == true)
        if case .text(let value) = chapter.data {
            XCTAssertTrue(value.contains("<p>This diagnostics report can help"))
        } else {
            XCTFail("Expected text diagnostics")
        }
    }

    func testCustomFormatterPreservesBrowserHTMLAndStructuredData() async throws {
        let suiteName = "DiagnosticsReporterTests-\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        userDefaults.set("agent-friendly", forKey: "mode")
        let reporter = UserDefaultsReporter(userDefaults: userDefaults, keys: ["mode"])

        let report = await DiagnosticsReporter.create(using: [reporter])
        let html = String(data: report.data, encoding: .utf8)!
        let document = try XCTUnwrap(html.diagnosticsReportDocument)
        let chapter = try XCTUnwrap(document.chapters.first)

        XCTAssertTrue(chapter.legacyHTML?.contains("<pre>") == true)
        XCTAssertTrue(chapter.legacyHTML?.contains("agent-friendly") == true)
        if case .table(let rows) = chapter.data {
            XCTAssertEqual(rows.first?.key, "mode")
            XCTAssertEqual(rows.first?.value, "agent-friendly")
        } else {
            XCTFail("Expected table diagnostics")
        }
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

    func testJSONReportAppliesFilters() async throws {
        let keyToFilter = UUID().uuidString
        let mockedReport = MockedReport(diagnostics: [keyToFilter: UUID().uuidString])
        let report = await DiagnosticsReporter.create(format: .json, using: [mockedReport], filters: [MockedFilter.self])
        let json = String(data: report.data, encoding: .utf8)!
        let document = try JSONDecoder().decode(DiagnosticsReportDocument.self, from: report.data)

        XCTAssertFalse(json.contains(keyToFilter))
        if case .text(let value)? = document.chapters.first?.data {
            XCTAssertEqual(value, "FILTERED")
        } else {
            XCTFail("Expected filtered text diagnostics")
        }
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

private extension String {
    var diagnosticsReportDocument: DiagnosticsReportDocument? {
        guard
            let startRange = range(of: "<script id=\"diagnostics-report-data\" type=\"application/json\">"),
            let endRange = range(of: "</script>", range: startRange.upperBound..<endIndex) else {
            return nil
        }

        let json = String(self[startRange.upperBound..<endRange.lowerBound])
        return try? JSONDecoder().decode(DiagnosticsReportDocument.self, from: Data(json.utf8))
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
