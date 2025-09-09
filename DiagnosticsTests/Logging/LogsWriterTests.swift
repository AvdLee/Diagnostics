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
