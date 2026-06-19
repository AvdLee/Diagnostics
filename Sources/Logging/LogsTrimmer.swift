//
//  LogsTrimmer.swift
//
//
//  Created by Antoine van der Lee on 01/03/2024.
//

import Foundation

struct LogsTrimmer: Sendable {
    let numberOfLinesToTrim: Int

    private static let regex: NSRegularExpression = {
        /// Any line that starts with `<p class=` and ends with `</p>`.
        /// This basically matches any log line that comes with a CSS class.
        let pattern = "<p class=\".*?\">.*?</p>"
        return try! NSRegularExpression(pattern: pattern)
    }()

    func trim(data: inout Data) {
        var logs = String(decoding: data, as: UTF8.self)
        let legacyRecordsTrimmed = trimLegacyRecords(from: &logs, maximumNumberOfRecordsToTrim: numberOfLinesToTrim)
        guard legacyRecordsTrimmed < numberOfLinesToTrim else {
            data = Data(logs.utf8)
            return
        }

        _ = trimStructuredRecords(
            from: &logs,
            maximumNumberOfRecordsToTrim: numberOfLinesToTrim - legacyRecordsTrimmed
        )
        data = Data(logs.utf8)
    }

    private func trimLegacyRecords(from logs: inout String, maximumNumberOfRecordsToTrim: Int) -> Int {
        let nsLogs = logs as NSString
        let matches = LogsTrimmer.regex
            .matches(in: logs, range: NSRange(location: 0, length: nsLogs.length))

        let linesToRemove = matches.prefix(maximumNumberOfRecordsToTrim)
        guard let firstMatch = linesToRemove.first, let lastMatch = linesToRemove.last else {
            return 0
        }

        let range = NSRange(
            location: firstMatch.range.location,
            length: lastMatch.range.upperBound - firstMatch.range.location
        )

        logs = nsLogs.replacingCharacters(in: range, with: "")
        return linesToRemove.count
    }

    private func trimStructuredRecords(from logs: inout String, maximumNumberOfRecordsToTrim: Int) -> Int {
        var trimmedRecords = 0
        var lines = logs.components(separatedBy: .newlines)

        while trimmedRecords < maximumNumberOfRecordsToTrim {
            guard let index = lines.firstIndex(where: { line in
                line.hasPrefix(DiagnosticsLogRecord.linePrefix) && line.contains("\"type\":\"log\"")
            }) else {
                break
            }

            lines.remove(at: index)
            trimmedRecords += 1
        }

        guard trimmedRecords > 0 else { return 0 }

        logs = lines.joined(separator: "\n")
        return trimmedRecords
    }
}
