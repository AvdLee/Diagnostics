//
//  LogsWriterTests.swift
//  Diagnostics
//
//  Created by A.J. van der Lee on 01/07/2025.
//

import XCTest
@testable import Diagnostics

final class LogsWriterTests: XCTestCase {

    private var tempLogFileURL: URL!

    override func setUpWithError() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
        tempLogFileURL = tempDirectory.appendingPathComponent("test_log.txt")
        // Start with an empty file
        FileManager.default.createFile(atPath: tempLogFileURL.path, contents: nil)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempLogFileURL)
    }

    func testWriteAppendsData() throws {
        let writer = LogsWriter(logFileLocation: tempLogFileURL, maximumLogSize: 1024 * 1024)
        let log = SystemLog(line: "Test log line")

        writer.write(log)

        let data = try Data(contentsOf: tempLogFileURL)
        let contents = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(contents.contains("Test log line"))
        XCTAssertTrue(contents.contains(DiagnosticsLogRecord.linePrefix))
    }

    func testWriteAppendsStructuredDataAfterLegacyContent() throws {
        let legacyContent = """
        <summary><div class="session-header"><p><span>Date: </span>2026-01-01</p></div></summary>
        <p class="debug"><span class="log-message">Legacy event</span></p>

        """
        try Data(legacyContent.utf8).write(to: tempLogFileURL)

        let writer = LogsWriter(logFileLocation: tempLogFileURL, maximumLogSize: 1024 * 1024)
        writer.write(SystemLog(line: "Structured event"))

        let data = try Data(contentsOf: tempLogFileURL)
        let contents = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(contents.contains("Legacy event"))
        XCTAssertTrue(contents.contains("Structured event"))
        XCTAssertTrue(contents.contains(DiagnosticsLogRecord.linePrefix))
    }

    func testTrimmingOccursWhenExceedingMaxSize() throws {
        let systemLogMessage = SystemLog(line: "Old log Message")
        let systemLogSize = systemLogMessage.logData.count
        
        /// Max of 100 log messages
        let maximumLogSize = systemLogSize * 100
        
        let writer = LogsWriter(logFileLocation: tempLogFileURL, maximumLogSize: maximumLogSize)

        // Pre-fill log to exceed max size
        for _ in (0..<100) {
            writer.write(systemLogMessage)
        }

        // Write again to trigger trimming
        let newLog = SystemLog(line: "New log entry")
        writer.write(newLog)

        let data = try Data(contentsOf: tempLogFileURL)
        let contents = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(contents.contains("New log entry"))

        // After trimming, total size should be below max size
        XCTAssertLessThanOrEqual(data.count, maximumLogSize)
    }
    
    func testTrimmingLogItemsOccursWhenExceedingMaxSize() throws {
        let logItemMessage = LogItem(.debug(message: "Log entry"), file: #file, function: #function, line: #line)
        let logItemSize = logItemMessage.logData.count
        
        /// Max of 100 log messages
        let maximumLogSize = logItemSize * 100
        
        let writer = LogsWriter(logFileLocation: tempLogFileURL, maximumLogSize: maximumLogSize)

        // Pre-fill log to exceed max size
        for _ in (0..<100) {
            writer.write(logItemMessage)
        }

        // Write again to trigger trimming
        let newLog = LogItem(.debug(message: "New log entry"), file: #file, function: #function, line: #line)
        writer.write(newLog)

        let data = try Data(contentsOf: tempLogFileURL)
        let contents = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(contents.contains("New log entry"))

        // After trimming, total size should be below max size
        XCTAssertLessThanOrEqual(data.count, maximumLogSize)
    }

    func testNoTrimmingWhenUnderMaxSize() throws {
        let writer = LogsWriter(logFileLocation: tempLogFileURL, maximumLogSize: 500)
        let log = SystemLog(line: "Small log entry")
        
        writer.write(log)

        let data = try Data(contentsOf: tempLogFileURL)
        XCTAssertGreaterThan(data.count, 0)
        XCTAssertLessThan(data.count, 500)
    }
    
    func testTrimmingReducesLargeOverflowBelowMaxSize() throws {
        let record = SystemLog(line: "Old log Message")
        let maximumLogSize = record.logData.count * 100
        let writer = LogsWriter(logFileLocation: tempLogFileURL, maximumLogSize: maximumLogSize)

        // Pre-fill to three times the maximum size without triggering trimming.
        var prefill = Data()
        while prefill.count <= maximumLogSize * 3 {
            prefill.append(record.logData)
        }
        try prefill.write(to: tempLogFileURL)

        // A single write should trim the file all the way below the maximum size.
        writer.write(SystemLog(line: "New log entry"))

        let data = try Data(contentsOf: tempLogFileURL)
        XCTAssertLessThanOrEqual(data.count, maximumLogSize)
        XCTAssertTrue(String(decoding: data, as: UTF8.self).contains("New log entry"))
    }

    func testRepeatedTrimmingKeepsLogBounded() throws {
        let record = SystemLog(line: "Repeated log entry 0")
        let maximumLogSize = record.logData.count * 20
        let writer = LogsWriter(logFileLocation: tempLogFileURL, maximumLogSize: maximumLogSize)

        for index in 0..<100 {
            writer.write(SystemLog(line: "Repeated log entry \(index)"))
        }

        let data = try Data(contentsOf: tempLogFileURL)
        let contents = String(decoding: data, as: UTF8.self)
        XCTAssertLessThanOrEqual(data.count, maximumLogSize)
        XCTAssertTrue(contents.contains("Repeated log entry 99"))
    }

    func testWriteRecordLargerThanMaximumSizeDoesNotTrap() throws {
        let writer = LogsWriter(logFileLocation: tempLogFileURL, maximumLogSize: 100)
        let hugeLine = String(repeating: "A", count: 1000)

        writer.write(SystemLog(line: hugeLine))

        // The oversized record itself is trimmable, so the file ends up bounded
        // instead of terminating the app with an assertion failure.
        let data = try Data(contentsOf: tempLogFileURL)
        XCTAssertLessThanOrEqual(data.count, 100)
    }

    func testFailingTrimDoesNotTerminateAndKeepsAppendedData() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
            try? FileManager.default.removeItem(at: directory)
        }

        let fileURL = directory.appendingPathComponent("locked_log.txt")
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)

        let record = SystemLog(line: "Old log Message")
        let maximumLogSize = record.logData.count * 10
        var prefill = Data()
        while prefill.count <= maximumLogSize {
            prefill.append(record.logData)
        }
        try prefill.write(to: fileURL)

        // Make the parent directory read-only so the atomic replacement cannot
        // create its temporary file. The log file itself stays writable, so
        // appending still succeeds.
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory.path)

        let writer = LogsWriter(logFileLocation: fileURL, maximumLogSize: maximumLogSize)
        writer.write(SystemLog(line: "New log entry"))

        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
        let contents = String(decoding: try Data(contentsOf: fileURL), as: UTF8.self)
        XCTAssertTrue(contents.contains("New log entry"))
    }

    func testLogsWriterPerformance() {
        measure {
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempLogFileURL = tempDirectory.appendingPathComponent("test_log.txt")
            // Start with an empty file
            FileManager.default.createFile(atPath: tempLogFileURL.path, contents: nil)
            
            let writer = LogsWriter(logFileLocation: tempLogFileURL, maximumLogSize: 1_000_000)
            
            for i in 0..<1000 {
                let log = SystemLog(line: "Test log line \(i)")
                writer.write(log)
            }
            
            try? FileManager.default.removeItem(at: tempLogFileURL)
        }
    }
}
