//
//  LogsTrimmerTests.swift
//  
//
//  Created by Antoine van der Lee on 01/03/2024.
//
//  swiftlint:disable line_length

@testable import Diagnostics
import Foundation
import Testing

@Suite("LogsTrimmer")
struct LogsTrimmerTests {
    private let session = NewSession().logData
    private let records = (0..<10).map { SystemLog(line: "Structured log \($0)").logData }

    @Test("Drops legacy HTML sessions and blank lines before structured records")
    func dropsLegacyPrefixAndBlankLines() throws {
        let legacy = """
        <summary><div class="session-header"><p><span>Date: </span>2024-02-20 10:33:47</p><p><span>System: </span>iOS 16.3</p></div></summary>
        <p class="system"><span class="log-date">2024-02-20 10:33:47</span><span class="log-separator"> | </span><span class="log-message">SYSTEM: Old legacy log</span></p>
        continuation of a legacy message


        """
        var input = Data(legacy.utf8)
        input.append(session)
        input.append(Data("\n\n  \n".utf8))
        input.append(records[0])
        input.append(Data("\n".utf8))
        input.append(records[1])

        let output = try #require(LogsTrimmer.trim(input, toTargetSize: input.count))

        #expect(output == session + records[0] + records[1])
    }

    @Test("Drops empty system records")
    func dropsEmptySystemRecords() throws {
        let input = session + SystemLog(line: "").logData + records[0] + SystemLog(line: "").logData

        let output = try #require(LogsTrimmer.trim(input, toTargetSize: input.count))

        #expect(output == session + records[0])
    }

    @Test("Messages containing record markers are not treated as session starts or empty system records")
    func ignoresMarkersInsideMessages() throws {
        let lookalikes = [
            SystemLog(line: "\"type\":\"sessionStart\""),
            SystemLog(line: "\"message\":\"SYSTEM: \",")
        ].map(\.logData).reduce(Data(), +)
        let input = session + records[0] + lookalikes
        let expectedOutput = session + lookalikes

        let output = try #require(LogsTrimmer.trim(input, toTargetSize: expectedOutput.count))

        #expect(output == expectedOutput)
    }

    @Test("Keeps the newest records that fit in the target, in order")
    func keepsNewestRecordsWithinTarget() throws {
        let input = session + records.reduce(Data(), +)
        let expectedOutput = session + records.suffix(3).reduce(Data(), +)

        let output = try #require(LogsTrimmer.trim(input, toTargetSize: expectedOutput.count))

        #expect(output == expectedOutput)
    }

    @Test("Drops additional old records to keep the session start of the oldest kept record")
    func makesRoomForSessionStart() throws {
        let input = session + records.reduce(Data(), +)
        /// Fits the session start and two and a half records, so the budget alone would keep more than two records.
        let targetSize = session.count + records[0].count * 5 / 2

        let output = try #require(LogsTrimmer.trim(input, toTargetSize: targetSize))

        #expect(output.count <= targetSize)
        #expect(output == session + records.suffix(2).reduce(Data(), +))
    }

    @Test("Does not prepend an older session start when a newer one is kept")
    func keepsNewerSessionStartOnly() throws {
        let newerSession = NewSession().logData
        let input = session + records.prefix(5).reduce(Data(), +) + newerSession + records.suffix(2).reduce(Data(), +)
        let expectedOutput = newerSession + records.suffix(2).reduce(Data(), +)

        let output = try #require(LogsTrimmer.trim(input, toTargetSize: expectedOutput.count))

        #expect(output == expectedOutput)
    }

    @Test("Keeps the newest structured record from mixed-format logs")
    func trimsMixedFormatLogs() throws {
        let legacy = Data("<p class=\"system\"><span class=\"log-message\">Old legacy log</span></p>\n".utf8)
        let input = legacy + session + records[9]

        let output = try #require(LogsTrimmer.trim(input, toTargetSize: session.count + records[9].count))

        let outputString = String(decoding: output, as: UTF8.self)
        #expect(!outputString.contains("Old legacy log"))
        #expect(outputString.contains("\"type\":\"sessionStart\""))
        #expect(outputString.contains("Structured log 9"))
    }

    @Test("Returns nil when nothing can be trimmed")
    func returnsNilWithoutProgress() {
        let input = session + records[0]

        #expect(LogsTrimmer.trim(input, toTargetSize: input.count) == nil)
    }

    @Test("Returns empty data when even the newest record exceeds the target")
    func dropsRecordLargerThanTarget() throws {
        let input = SystemLog(line: String(repeating: "A", count: 1000)).logData

        let output = try #require(LogsTrimmer.trim(input, toTargetSize: 100))

        #expect(output.isEmpty)
    }
}
//  swiftlint:enable line_length
