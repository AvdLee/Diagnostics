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

    var diagnostics: String {
        do {
            guard let data = try DiagnosticsLogger.standard.readLog(), let logs = String(data: data, encoding: .utf8) else {
                return "Parsing the log failed (Unknown error)"
            }

            let sessions = logs.components(separatedBy: "\n\n---\n\n").reversed()
            var diagnostics = ""
            sessions.forEach { session in
                guard !session.isEmpty else { return }

                diagnostics += "<div class=\"collapsible-session\">"
                diagnostics += "<details>"
                if session.isOldStyleSession {
                    let title = session.split(whereSeparator: \.isNewline).first ?? "Unknown session title"
                    diagnostics += "<summary>\(title)</summary>"
                    diagnostics += "<pre>\(session.addingHTMLEncoding())</pre>"
                } else {
                    diagnostics += session
                }
                diagnostics += "</details>"
                diagnostics += "</div>"
            }
            return diagnostics
        } catch {
            return "Parsing the log failed (\(error.localizedDescription))"
        }
    }

    func report() -> DiagnosticsChapter {
        return DiagnosticsChapter(title: title, diagnostics: diagnostics, formatter: Self.self)
    }
}

extension LogsReporter: HTMLFormatting {
    static func format(_ diagnostics: Diagnostics) -> HTML {
        return "<div id=\"log-sessions\">\(diagnostics)</div>"
    }
}

private extension String {
    var isOldStyleSession: Bool {
        !contains("class=\"session-header")
    }
}
