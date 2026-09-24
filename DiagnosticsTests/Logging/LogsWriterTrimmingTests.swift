//
//  LogsWriterTrimmingTests.swift
//  DiagnosticsTests
//

@testable import Diagnostics
import Foundation
import Testing

@Suite("LogsWriter trimming")
struct LogsWriterTrimmingTests {
    private let logFileLocation = FileManager.default.temporaryDirectory
        .appendingPathComponent("LogsWriterTrimmingTests-\(UUID().uuidString).txt")
    private let maximumLogSize = 64 * 1024

    private var writer: LogsWriter {
        LogsWriter(logFileLocation: logFileLocation, maximumLogSize: maximumLogSize)
    }

    private func fileSize() throws -> Int {
        try Data(contentsOf: logFileLocation).count
    }

    @Test("Trims a production-shaped log to the target in a single write, keeping the newest records in order")
    func trimsProductionShapedLog() throws {
        defer { try? FileManager.default.removeItem(at: logFileLocation) }
        let fixture = LogFixture.productionShaped(minimumSize: maximumLogSize)
        try fixture.data.write(to: logFileLocation)

        let newestRecord = SystemLog(line: "Newest record").logData
        #expect(writer.write(SystemLog(line: "Newest record")) == .trimmed)

        let data = try Data(contentsOf: logFileLocation)
        let contents = String(decoding: data, as: UTF8.self)
        #expect(data.count <= writer.trimTargetSize)
        #expect(!contents.contains("session-header"))
        #expect(!contents.contains("\n\n"))
        #expect(!contents.contains("\"message\":\"SYSTEM: \","))

        let keptLines = LogFixture.lines(in: data)
        let firstLine = try #require(keptLines.first)
        #expect(firstLine.contains("\"type\":\"sessionStart\""))

        let expectedLines = fixture.meaningfulLines + [LogFixture.line(from: newestRecord)]
        let keptRecords = Array(keptLines.dropFirst())
        #expect(keptRecords.count > 100)
        #expect(Array(expectedLines.suffix(keptRecords.count)) == keptRecords)
    }

    @Test("Appends that stay under the maximum size do not trim again after a trim")
    func doesNotTrimAgainUnderMaximumSize() throws {
        defer { try? FileManager.default.removeItem(at: logFileLocation) }
        try LogFixture.productionShaped(minimumSize: maximumLogSize).data.write(to: logFileLocation)
        #expect(writer.write(SystemLog(line: "Trigger")) == .trimmed)

        var index = 0
        func nextRecord() -> SystemLog {
            defer { index += 1 }
            return SystemLog(line: String(format: "Record after trim %06d", index))
        }

        var record = nextRecord()
        var size = try fileSize()
        var appendsUnderMaximum = 0
        while size + record.logData.count <= maximumLogSize {
            #expect(writer.write(record) == .appended)
            size += record.logData.count
            appendsUnderMaximum += 1
            record = nextRecord()
        }
        #expect(try fileSize() == size)
        #expect(appendsUnderMaximum > 100)

        #expect(writer.write(record) == .trimmed)
        #expect(try fileSize() <= writer.trimTargetSize)
    }

    @Test("Writes multiple records as a single ordered append")
    func writesBatchInOrder() throws {
        defer { try? FileManager.default.removeItem(at: logFileLocation) }
        FileManager.default.createFile(atPath: logFileLocation.path, contents: nil)
        let records = ["First", "Second", "Third"].map { SystemLog(line: $0) }

        #expect(writer.write(records) == .appended)

        let data = try Data(contentsOf: logFileLocation)
        #expect(data == records.map(\.logData).reduce(Data(), +))
    }

    @Test("Trimmed mixed-format logs render sessions with their metadata")
    func trimmedLogParsesIntoSessionsWithMetadata() throws {
        defer { try? FileManager.default.removeItem(at: logFileLocation) }
        try LogFixture.productionShaped(minimumSize: maximumLogSize).data.write(to: logFileLocation)
        #expect(writer.write(SystemLog(line: "Newest record")) == .trimmed)

        let report = DiagnosticsLogParser().parse(String(decoding: try Data(contentsOf: logFileLocation), as: UTF8.self))

        #expect(!report.sessions.isEmpty)
        #expect(report.sessions.allSatisfy { !$0.metadata.isEmpty && $0.legacyHTML == nil })
        let newestEvent = try #require(report.sessions.last?.events.last)
        #expect(newestEvent.message == "SYSTEM: Newest record")
    }
}
