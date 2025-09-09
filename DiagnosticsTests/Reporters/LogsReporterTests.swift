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
        let diagnostics = LogsReporter().report().diagnostics as! String
        XCTAssertTrue(diagnostics.contains(identifier), "Diagnostics is \(diagnostics)")
        XCTAssertEqual(diagnostics.debugLogs.count, 1)
        let debugLog = try XCTUnwrap(diagnostics.debugLogs.first)
        XCTAssertTrue(debugLog.contains("<span class=\"log-prefix\">LogsReporterTests.swift:L28</span>"), "Prefix should be added")
        XCTAssertTrue(debugLog.contains("<span class=\"log-message\">&lt;b&gt;\(identifier)&lt;/b&gt;</span>"), "Log message should be added to \(debugLog)")
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
        let diagnostics = LogsReporter().report().diagnostics as! String
        XCTAssertTrue(diagnostics.contains("testCase"))
        XCTAssertEqual(diagnostics.errorLogs.count, 1)
        let errorLog = try XCTUnwrap(diagnostics.errorLogs.first)
        XCTAssertTrue(errorLog.contains("<span class=\"log-message\">ERROR: testCase | &lt;b&gt;example description&lt;/b&gt"))
    }

    /// It should reverse the order of sessions to have the most recent session on top.
    func testReverseSessions() throws {
        DiagnosticsLogger.log(message: "first")
        DiagnosticsLogger.standard.startNewSession()
        DiagnosticsLogger.log(message: "second")
        let diagnostics = LogsReporter().report().diagnostics as! String
        let firstIndex = try XCTUnwrap(diagnostics.range(of: "first")?.lowerBound)
        let secondIndex = try XCTUnwrap(diagnostics.range(of: "second")?.lowerBound)
        XCTAssertTrue(firstIndex > secondIndex)
    }
}
