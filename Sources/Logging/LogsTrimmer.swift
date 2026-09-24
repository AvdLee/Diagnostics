//
//  LogsTrimmer.swift
//
//
//  Created by Antoine van der Lee on 01/03/2024.
//

import Foundation

/// Trims the log file in a single linear pass by keeping the newest structured records that fit in a byte budget.
///
/// Content without diagnostic value is dropped first: legacy HTML sessions written before the first
/// `DIAGNOSTICS_JSON` record, blank lines, and empty system records.
enum LogsTrimmer {
    private static let newline = UInt8(ascii: "\n")
    private static let linePrefix = Data(DiagnosticsLogRecord.linePrefix.utf8)
    private static let sessionStartMarker = Data("\"type\":\"sessionStart\"".utf8)
    private static let emptySystemMessageMarkers = [
        Data("\"message\":\"SYSTEM: \",".utf8),
        Data("\"message\":\"SYSTEM: \"}".utf8)
    ]

    private struct Line {
        let range: Range<Int>
        let isSessionStart: Bool
        /// Index of the closest `sessionStart` line at or before this line.
        let sessionStartIndex: Int?
    }

    /// Returns the trimmed log data, or `nil` when trimming would not make the data smaller.
    static func trim(_ data: Data, toTargetSize targetSize: Int) -> Data? {
        guard data.startIndex == 0 else {
            return trim(Data(data), toTargetSize: targetSize)
        }
        let lines = structuredLines(in: data)

        var firstKeptIndex = lines.endIndex
        var keptSize = 0
        while firstKeptIndex > lines.startIndex {
            let lineSize = lines[firstKeptIndex - 1].range.count
            guard keptSize + lineSize <= targetSize else { break }
            keptSize += lineSize
            firstKeptIndex -= 1
        }

        /// Keep the `sessionStart` of the oldest kept record so its events keep their session metadata.
        var sessionStartIndex: Int?
        while firstKeptIndex < lines.endIndex {
            let firstLine = lines[firstKeptIndex]
            guard !firstLine.isSessionStart, let index = firstLine.sessionStartIndex else {
                sessionStartIndex = nil
                break
            }

            sessionStartIndex = index
            if keptSize + lines[index].range.count <= targetSize { break }

            keptSize -= firstLine.range.count
            firstKeptIndex += 1
        }
        if firstKeptIndex == lines.endIndex {
            sessionStartIndex = nil
        }

        let sessionStartSize = sessionStartIndex.map { lines[$0].range.count } ?? 0
        guard keptSize + sessionStartSize < data.count else { return nil }

        var trimmedData = Data(capacity: keptSize + sessionStartSize)
        if let sessionStartIndex {
            trimmedData.append(data[lines[sessionStartIndex].range])
        }
        for line in lines[firstKeptIndex...] {
            trimmedData.append(data[line.range])
        }
        return trimmedData
    }

    /// Returns all non-empty structured records, with ranges that include their trailing newline.
    private static func structuredLines(in data: Data) -> [Line] {
        var lines: [Line] = []
        var latestSessionStartIndex: Int?

        data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            guard let baseAddress = buffer.baseAddress else { return }
            let bytes = baseAddress.assumingMemoryBound(to: UInt8.self)
            let count = buffer.count

            var lineStart = 0
            while lineStart < count {
                let lineEnd: Int
                let nextLineStart: Int
                if let newlinePointer = memchr(bytes + lineStart, Int32(newline), count - lineStart) {
                    lineEnd = bytes.distance(to: newlinePointer.assumingMemoryBound(to: UInt8.self))
                    nextLineStart = lineEnd + 1
                } else {
                    lineEnd = count
                    nextLineStart = count
                }

                let line = UnsafeRawBufferPointer(start: bytes + lineStart, count: lineEnd - lineStart)
                if line.starts(with: linePrefix), !isEmptySystemRecord(line) {
                    let isSessionStart = contains(sessionStartMarker, in: line)
                    if isSessionStart {
                        latestSessionStartIndex = lines.count
                    }
                    lines.append(Line(
                        range: lineStart..<nextLineStart,
                        isSessionStart: isSessionStart,
                        sessionStartIndex: latestSessionStartIndex
                    ))
                }
                lineStart = nextLineStart
            }
        }

        return lines
    }

    private static func isEmptySystemRecord(_ line: UnsafeRawBufferPointer) -> Bool {
        emptySystemMessageMarkers.contains { contains($0, in: line) }
    }

    private static func contains(_ marker: Data, in line: UnsafeRawBufferPointer) -> Bool {
        marker.withUnsafeBytes { markerBuffer in
            guard let markerAddress = markerBuffer.baseAddress, let lineAddress = line.baseAddress else { return false }
            return memmem(lineAddress, line.count, markerAddress, markerBuffer.count) != nil
        }
    }
}
