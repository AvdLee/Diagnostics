//
//  SwiftLogHandlerTests.swift
//  DiagnosticsTests
//

@testable import Diagnostics
import Logging
import XCTest

final class SwiftLogHandlerTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try DiagnosticsLogger.setup()
    }

    override func tearDownWithError() throws {
        try DiagnosticsLogger.standard.deleteLogs()
        try super.tearDownWithError()
    }

    func testDebugMessageIsLoggedAsDebug() throws {
        let handler = DiagnosticsLogger.SwiftLogHandler(label: "test.debug")
        handler.log(
            level: .debug,
            message: Logger.Message(stringLiteral: "debug message"),
            metadata: nil,
            source: "TestSource",
            file: "TestFile.swift",
            function: "testFunc()",
            line: 42
        )

        let logData = try XCTUnwrap(DiagnosticsLogger.standard.readLog())
        let log = String(decoding: logData, as: UTF8.self)

        XCTAssertTrue(log.contains("debug message"))
        XCTAssertTrue(log.contains("\"level\":\"debug\""))
        XCTAssertTrue(log.contains("[test.debug]"))
    }

    func testErrorMessageIsLoggedAsError() throws {
        let handler = DiagnosticsLogger.SwiftLogHandler(label: "test.error")
        handler.log(
            level: .error,
            message: Logger.Message(stringLiteral: "something broke"),
            metadata: nil,
            source: "TestSource",
            file: "TestFile.swift",
            function: "testFunc()",
            line: 10
        )

        let logData = try XCTUnwrap(DiagnosticsLogger.standard.readLog())
        let log = String(decoding: logData, as: UTF8.self)

        XCTAssertTrue(log.contains("something broke"))
        XCTAssertTrue(log.contains("\"level\":\"error\""))
    }

    func testCriticalMessageIsLoggedAsError() throws {
        let handler = DiagnosticsLogger.SwiftLogHandler(label: "test.critical")
        handler.log(
            level: .critical,
            message: Logger.Message(stringLiteral: "fatal issue"),
            metadata: nil,
            source: "TestSource",
            file: "TestFile.swift",
            function: "testFunc()",
            line: 1
        )

        let logData = try XCTUnwrap(DiagnosticsLogger.standard.readLog())
        let log = String(decoding: logData, as: UTF8.self)

        XCTAssertTrue(log.contains("fatal issue"))
        XCTAssertTrue(log.contains("\"level\":\"error\""))
    }

    func testMetadataIsIncludedInMessage() throws {
        var handler = DiagnosticsLogger.SwiftLogHandler(
            label: "test.meta",
            metadata: ["requestID": "abc-123"]
        )
        handler.log(
            level: .info,
            message: Logger.Message(stringLiteral: "request received"),
            metadata: ["userID": "42"],
            source: "TestSource",
            file: "TestFile.swift",
            function: "testFunc()",
            line: 5
        )

        let logData = try XCTUnwrap(DiagnosticsLogger.standard.readLog())
        let log = String(decoding: logData, as: UTF8.self)

        XCTAssertTrue(log.contains("requestID"))
        XCTAssertTrue(log.contains("abc-123"))
        XCTAssertTrue(log.contains("userID"))
        XCTAssertTrue(log.contains("42"))
    }

    func testInfoLevelIsMappedToDebug() throws {
        let handler = DiagnosticsLogger.SwiftLogHandler(label: "test.info")
        handler.log(
            level: .info,
            message: Logger.Message(stringLiteral: "info message"),
            metadata: nil,
            source: "TestSource",
            file: "TestFile.swift",
            function: "testFunc()",
            line: 1
        )

        let logData = try XCTUnwrap(DiagnosticsLogger.standard.readLog())
        let log = String(decoding: logData, as: UTF8.self)

        XCTAssertTrue(log.contains("\"level\":\"debug\""))
    }

    func testCustomLoggerInstanceCanBeUsed() throws {
        let customLogger = DiagnosticsLogger()
        try DiagnosticsLogger.setup(customLogger)

        let handler = DiagnosticsLogger.SwiftLogHandler(label: "test.custom", logger: customLogger)
        handler.log(
            level: .warning,
            message: Logger.Message(stringLiteral: "custom logger message"),
            metadata: nil,
            source: "TestSource",
            file: "TestFile.swift",
            function: "testFunc()",
            line: 1
        )

        // Verify the custom logger instance is set up
        XCTAssertTrue(DiagnosticsLogger.isSetUp())
    }

    func testSubscriptMetadataAccess() {
        var handler = DiagnosticsLogger.SwiftLogHandler(label: "test.subscript")
        handler[metadataKey: "key1"] = "value1"

        XCTAssertEqual(handler.metadata["key1"]?.description, "value1")
    }
}