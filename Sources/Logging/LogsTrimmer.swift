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
        let nsLogs = logs as NSString
        let matches = LogsTrimmer.regex
            .matches(in: logs, range: NSRange(location: 0, length: nsLogs.length))

        let linesToRemove = matches.prefix(numberOfLinesToTrim)
        guard let firstMatch = linesToRemove.first, let lastMatch = linesToRemove.last else {
            return
        }

        let range = NSRange(
            location: firstMatch.range.location,
            length: lastMatch.range.upperBound - firstMatch.range.location
        )

        logs = nsLogs.replacingCharacters(in: range, with: "")
        data = Data(logs.utf8)
    }
}
