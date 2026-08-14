//
//  DiagnosticsLoggerTests.swift
//  DiagnosticsTests
//

@testable import Diagnostics
import XCTest

final class DiagnosticsLoggerTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try DiagnosticsLogger.setup()
    }

    override func tearDownWithError() throws {
        try DiagnosticsLogger.standard.deleteLogs()
        try super.tearDownWithError()
    }

    func testSynchronousCrashLogIsPersistedBeforeReturning() throws {
        let exception = NSException(name: .genericException, reason: "Synchronous crash test")

        DiagnosticsLogger.standard.logSynchronously(ExceptionLog(exception, description: "Uncaught Exception"))

        let logData = try XCTUnwrap(DiagnosticsLogger.standard.readLog())
        let log = String(decoding: logData, as: UTF8.self)

        XCTAssertTrue(log.contains(DiagnosticsLogRecord.linePrefix))
        XCTAssertTrue(log.contains("\"level\":\"crash\""))
        XCTAssertTrue(log.contains("Synchronous crash test"))
        XCTAssertTrue(log.contains("Uncaught Exception"))
    }

    /// Exercises trimming through the logger's serial queue at the production 2 MB
    /// limit while reads happen concurrently, mirroring report generation during
    /// heavy logging.
    func testTrimmingViaLoggerQueueWithConcurrentReads() throws {
        let logFileLocation = FileManager.default.applicationSupportDirectory.appendingPathComponent("diagnostics_log.txt")
        let maximumLogSize = 2 * 1024 * 1024

        let record = SystemLog(line: "Prefilled log entry").logData
        var prefill = Data(capacity: maximumLogSize + record.count)
        while prefill.count <= maximumLogSize {
            prefill.append(record)
        }
        try prefill.write(to: logFileLocation)

        let readsFinished = expectation(description: "Concurrent reads finished")
        DispatchQueue.global().async {
            for _ in 0..<10 {
                _ = try? DiagnosticsLogger.standard.readLog()
            }
            readsFinished.fulfill()
        }

        for index in 0..<10 {
            DiagnosticsLogger.log(message: "Concurrent log entry \(index)")
        }

        wait(for: [readsFinished], timeout: 30)

        let logData = try XCTUnwrap(DiagnosticsLogger.standard.readLog())
        XCTAssertLessThanOrEqual(logData.count, maximumLogSize)
        XCTAssertTrue(String(decoding: logData, as: UTF8.self).contains("Concurrent log entry 9"))
    }

    #if os(macOS)
    /// On unsandboxed macOS processes (including the `swift test` runner), the Application
    /// Support directory used for the log file must be scoped by the current bundle identifier
    /// so that multiple unsandboxed apps embedding this package do not collide on the same
    /// `diagnostics_log.txt` at `~/Library/Application Support/`.
    func testApplicationSupportDirectoryIsScopedByBundleIDWhenUnsandboxed() throws {
        try XCTSkipIf(FileManager.isSandboxed, "Application Support directory remains container-scoped in sandboxed processes.")

        let bundleIdentifier = try XCTUnwrap(Bundle.main.bundleIdentifier)
        let url = FileManager.default.applicationSupportDirectory
        XCTAssertEqual(
            url.lastPathComponent,
            bundleIdentifier,
            "Expected Application Support directory to end with \(bundleIdentifier); got \(url.path)"
        )
    }
    #endif
}
