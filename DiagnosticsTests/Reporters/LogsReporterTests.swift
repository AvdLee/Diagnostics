//
//  LogsReporterTests.swift
//  DiagnosticsTests
//
//  Created by Antoine van der Lee on 03/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import XCTest
@testable import Diagnostics

final class LogsReporterTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try DiagnosticsLogger.setup()
    }

    override func tearDownWithError() throws {
        try DiagnosticsLogger.standard.deleteLogs()
        try super.tearDownWithError()
    }

    /// It should show logged messages.
    func testMessagesLog() throws {
        let identifier = UUID().uuidString
        let message = "<b>\(identifier)</b>"
        DiagnosticsLogger.log(message: message)
        let diagnostics = LogsReporter().report().diagnostics as! DiagnosticsLogReport
        let debugLogs = diagnostics.sessions.flatMap(\.events).filter { $0.level == "debug" }
        let html = diagnostics.html()
        XCTAssertTrue(html.contains(identifier), "Diagnostics is \(html)")
        XCTAssertEqual(debugLogs.count, 1)
        let debugLog = try XCTUnwrap(debugLogs.first)
        XCTAssertEqual(debugLog.prefix, "LogsReporterTests.swift:L28", "Prefix should be added")
        XCTAssertEqual(debugLog.message, message, "Raw message should be preserved for agents")
        XCTAssertTrue(html.contains("<span class=\"log-prefix\">LogsReporterTests.swift:L28</span>"), "Prefix should be added")
        XCTAssertTrue(html.contains("<span class=\"log-message\">&lt;b&gt;\(identifier)&lt;/b&gt;</span>"), "Log message should be added to \(html)")
    }

    /// It should show errors.
    func testErrorLog() throws {
        enum Error: LocalizedError {
            case testCase

            var errorDescription: String? {
                return "<b>example description</b>"
            }
        }

        DiagnosticsLogger.log(error: Error.testCase)
        let diagnostics = LogsReporter().report().diagnostics as! DiagnosticsLogReport
        let errorLogs = diagnostics.sessions.flatMap(\.events).filter { $0.level == "error" }
        let html = diagnostics.html()
        XCTAssertTrue(html.contains("testCase"))
        XCTAssertEqual(errorLogs.count, 1)
        let errorLog = try XCTUnwrap(errorLogs.first)
        XCTAssertTrue(errorLog.message.contains("ERROR: testCase | <b>example description</b>"))
        XCTAssertTrue(html.contains("<span class=\"log-message\">ERROR: testCase | &lt;b&gt;example description&lt;/b&gt"))
    }

    /// It should reverse the order of sessions to have the most recent session on top.
    func testReverseSessions() throws {
        DiagnosticsLogger.log(message: "first")
        DiagnosticsLogger.standard.startNewSession()
        DiagnosticsLogger.log(message: "second")
        let diagnostics = LogsReporter().report().diagnostics as! DiagnosticsLogReport
        let html = diagnostics.html()
        let firstIndex = try XCTUnwrap(html.range(of: "first")?.lowerBound)
        let secondIndex = try XCTUnwrap(html.range(of: "second")?.lowerBound)
        XCTAssertTrue(firstIndex > secondIndex)
    }

    /// It should keep historic legacy sessions readable when new structured records are appended after an app update.
    func testMixedLegacyAndStructuredSessions() throws {
        let legacySession = """

        ---

        <summary><div class="session-header"><p><span>Date: </span>2026-01-01 10:00:00</p><p><span>System: </span>iOS 18.0</p><p><span>Locale: </span>en</p><p><span>Version: </span>1.0 (1)</p></div></summary>
        <p class="debug"><span class="log-message">legacy historic event</span></p>
        """
        let structuredSession = String(decoding: NewSession().logData, as: UTF8.self)
        let structuredEvent = String(decoding: LogItem(.debug(message: "structured update event"), file: #file, function: #function, line: #line).logData, as: UTF8.self)

        let report = DiagnosticsLogParser().parse(legacySession + structuredSession + structuredEvent)
        let html = report.html()

        XCTAssertEqual(report.sessions.count, 2)
        XCTAssertTrue(html.contains("legacy historic event"))
        XCTAssertTrue(html.contains("structured update event"))
        let legacyIndex = try XCTUnwrap(html.range(of: "legacy historic event")?.lowerBound)
        let structuredIndex = try XCTUnwrap(html.range(of: "structured update event")?.lowerBound)
        XCTAssertTrue(structuredIndex < legacyIndex)
    }

    /// It should encode structured session metadata keys and values before rendering HTML.
    func testStructuredSessionMetadataHTMLEncoding() {
        let session = DiagnosticsLogSession(
            title: "Session",
            metadata: ["<Date>": "<2026-06-19>"]
        )

        let html = session.html()

        XCTAssertTrue(html.contains("&lt;Date&gt;"))
        XCTAssertTrue(html.contains("&lt;2026-06-19&gt;"))
        XCTAssertFalse(html.contains("<span><Date>: </span>"))
    }
}
