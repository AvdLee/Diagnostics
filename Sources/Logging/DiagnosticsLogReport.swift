//
//  DiagnosticsLogReport.swift
//  Diagnostics
//
//  Created by Diagnostics.
//

import Foundation

struct DiagnosticsLogReport: Diagnostics, Codable, Sendable {
    var sessions: [DiagnosticsLogSession]

    func html() -> HTML {
        var html = "<div id=\"log-sessions\">"
        sessions.reversed().forEach { session in
            html += session.html()
        }
        html += "</div>"
        return html
    }
}

struct DiagnosticsLogSession: Codable, Sendable {
    var id: String
    var title: String
    var metadata: [String: String]
    var events: [DiagnosticsLogEvent]
    var legacyHTML: String?

    init(
        id: String = UUID().uuidString,
        title: String,
        metadata: [String: String] = [:],
        events: [DiagnosticsLogEvent] = [],
        legacyHTML: String? = nil
    ) {
        self.id = id
        self.title = title
        self.metadata = metadata
        self.events = events
        self.legacyHTML = legacyHTML
    }

    func html() -> HTML {
        var html = "<div class=\"collapsible-session\"><details>"

        if let legacyHTML {
            if legacyHTML.isOldStyleSession {
                html += "<summary>\(title.addingHTMLEncoding())</summary>"
                html += "<pre>\(legacyHTML.addingHTMLEncoding())</pre>"
            } else {
                html += legacyHTML
            }
        } else {
            html += "<summary><div class=\"session-header\">"
            metadata.sorted(by: { $0.key < $1.key }).forEach { key, value in
                html += "<p><span>\(key): </span>\(value.addingHTMLEncoding())</p>"
            }
            html += "</div></summary>"
            events.forEach { event in
                html += event.html()
            }
        }

        html += "</details></div>"
        return html
    }
}

struct DiagnosticsLogEvent: Codable, Sendable {
    let date: String?
    let level: String
    let prefix: String?
    let message: String
    let legacyHTML: String?

    init(date: String?, level: String, prefix: String?, message: String, legacyHTML: String? = nil) {
        self.date = date
        self.level = level
        self.prefix = prefix
        self.message = message
        self.legacyHTML = legacyHTML
    }

    func html() -> HTML {
        if let legacyHTML {
            return legacyHTML
        }

        var parts: [String] = []
        if let date {
            parts.append("<span class=\"log-date\">\(date.addingHTMLEncoding())</span>")
        }
        if let prefix {
            parts.append("<span class=\"log-prefix\">\(prefix.addingHTMLEncoding())</span>")
        }
        parts.append("<span class=\"log-message\">\(message.addingHTMLEncoding())</span>")
        let content = parts.joined(separator: "<span class=\"log-separator\"> | </span>")
        return "<p class=\"\(level)\">\(content)</p>\n"
    }
}

struct DiagnosticsLogRecord: Codable, Sendable {
    static let linePrefix = "DIAGNOSTICS_JSON "

    let type: String
    let date: String?
    let level: String?
    let prefix: String?
    let message: String?
    let metadata: [String: String]?

    var lineData: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        guard
            let data = try? encoder.encode(self),
            let json = String(data: data, encoding: .utf8) else {
            return Data()
        }

        return Data("\(Self.linePrefix)\(json)\n".utf8)
    }

    init(loggable: Loggable) {
        self.type = "log"
        self.date = loggable.date.map(DateFormatter.current.string(from:))
        self.level = loggable.cssClass?.rawValue ?? "debug"
        self.prefix = loggable.prefix
        self.message = loggable.message.removingHTMLEncoding()
        self.metadata = nil
    }

    init(session: NewSession) {
        self.type = "sessionStart"
        self.date = session.metadata["Date"]
        self.level = nil
        self.prefix = nil
        self.message = nil
        self.metadata = session.metadata
    }

    init?(line: String) {
        guard line.hasPrefix(Self.linePrefix) else {
            return nil
        }

        let json = line.dropFirst(Self.linePrefix.count)
        guard let data = String(json).data(using: .utf8),
              let record = try? JSONDecoder().decode(Self.self, from: data) else {
            return nil
        }

        self = record
    }

    var session: DiagnosticsLogSession {
        let metadata = metadata ?? [:]
        let title = metadata["Date"].map { "Session \($0)" } ?? "Session"
        return DiagnosticsLogSession(title: title, metadata: metadata)
    }

    var event: DiagnosticsLogEvent? {
        guard type == "log", let message else {
            return nil
        }

        return DiagnosticsLogEvent(date: date, level: level ?? "debug", prefix: prefix, message: message)
    }
}

struct DiagnosticsLogParser: Sendable {
    func parse(_ logs: String) -> DiagnosticsLogReport {
        var sessions: [DiagnosticsLogSession] = []
        var currentStructuredSession: DiagnosticsLogSession?

        logs.components(separatedBy: "\n\n---\n\n").forEach { chunk in
            var legacyLines: [String] = []

            func flushLegacyLines() {
                let legacyHTML = legacyLines.joined(separator: "\n")
                legacyLines.removeAll()
                guard !legacyHTML.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

                let title = legacyHTML.split(whereSeparator: \.isNewline).first.map(String.init) ?? "Unknown session title"
                sessions.append(DiagnosticsLogSession(title: title, legacyHTML: legacyHTML))
            }

            chunk.components(separatedBy: .newlines).forEach { line in
                guard let record = DiagnosticsLogRecord(line: line) else {
                    legacyLines.append(line)
                    return
                }

                flushLegacyLines()

                if record.type == "sessionStart" {
                    if let currentStructuredSession {
                        sessions.append(currentStructuredSession)
                    }
                    currentStructuredSession = record.session
                } else if let event = record.event {
                    if currentStructuredSession == nil {
                        currentStructuredSession = DiagnosticsLogSession(title: "Session")
                    }
                    currentStructuredSession?.events.append(event)
                }
            }

            flushLegacyLines()
        }

        if let currentStructuredSession {
            sessions.append(currentStructuredSession)
        }

        return DiagnosticsLogReport(sessions: sessions)
    }
}

private extension String {
    var isOldStyleSession: Bool {
        !contains("class=\"session-header")
    }

    func removingHTMLEncoding() -> String {
        replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }
}
