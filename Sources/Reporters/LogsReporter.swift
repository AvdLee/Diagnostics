//
//  LogsReporter.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import Foundation

/// Creates a report chapter for all system and custom logs captured with the `DiagnosticsLogger`.
struct LogsReporter: DiagnosticsReporting {

    let title: String = "Session Logs"

    var diagnostics: DiagnosticsLogReport {
        do {
            guard let data = try DiagnosticsLogger.standard.readLog(), let logs = String(data: data, encoding: .utf8) else {
                return DiagnosticsLogReport(sessions: [
                    DiagnosticsLogSession(title: "Parsing failed", legacyHTML: "Parsing the log failed (Unknown error)")
                ])
            }

            return DiagnosticsLogParser().parse(logs)
        } catch {
            return DiagnosticsLogReport(sessions: [
                DiagnosticsLogSession(title: "Parsing failed", legacyHTML: "Parsing the log failed (\(error.localizedDescription))")
            ])
        }
    }

    func report() -> DiagnosticsChapter {
        return DiagnosticsChapter(title: title, diagnostics: diagnostics, formatter: Self.self)
    }
}

extension LogsReporter: HTMLFormatting {
    static func format(_ diagnostics: Diagnostics) -> HTML {
        return diagnostics.html()
    }
}
