//
//  DiagnosticsReportDocument.swift
//  Diagnostics
//
//  Created by Diagnostics.
//

import Foundation

struct DiagnosticsReportDocument: Codable, Sendable {
    let schemaVersion: Int
    let generatedAt: String
    let title: String
    let agentHints: [String]
    let chapters: [DiagnosticsReportDocumentChapter]

    init(title: String, chapters: [DiagnosticsChapter]) {
        self.schemaVersion = 1
        self.generatedAt = ISO8601DateFormatter().string(from: Date())
        self.title = title
        self.agentHints = [
            "Agents should read this JSON payload instead of the rendered HTML.",
            "Start with chapters where kind is logs, then inspect error and system events in the newest sessions first.",
            "Use legacyHTML only as a fallback for custom diagnostics that do not expose structured data yet."
        ]
        self.chapters = chapters.map(DiagnosticsReportDocumentChapter.init)
    }
}

struct DiagnosticsReportDocumentChapter: Codable, Sendable {
    let id: String
    let title: String
    let kind: String
    let data: DiagnosticsReportDocumentValue
    let legacyHTML: String?

    init(chapter: DiagnosticsChapter) {
        self.id = chapter.title.anchor
        self.title = chapter.title
        let reportDocumentValue = chapter.diagnostics.reportDocumentValue

        switch reportDocumentValue {
        case .logs:
            self.kind = "logs"
        case .table:
            self.kind = "table"
        case .preformatted:
            self.kind = "preformatted"
        case .text:
            self.kind = "text"
        case .legacyHTML:
            self.kind = "legacyHTML"
        }

        self.data = reportDocumentValue

        if case .legacyHTML(let html) = reportDocumentValue {
            self.legacyHTML = html
        } else {
            self.legacyHTML = nil
        }
    }
}

enum DiagnosticsReportDocumentValue: Codable, Sendable {
    case table([DiagnosticsReportTableRow])
    case text(String)
    case preformatted(String)
    case logs(DiagnosticsLogReport)
    case legacyHTML(String)

    private enum CodingKeys: String, CodingKey {
        case type
        case rows
        case value
        case sessions
    }

    private enum ValueType: String, Codable {
        case table
        case text
        case preformatted
        case logs
        case legacyHTML
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .table(let rows):
            try container.encode(ValueType.table, forKey: .type)
            try container.encode(rows, forKey: .rows)
        case .text(let value):
            try container.encode(ValueType.text, forKey: .type)
            try container.encode(value, forKey: .value)
        case .preformatted(let value):
            try container.encode(ValueType.preformatted, forKey: .type)
            try container.encode(value, forKey: .value)
        case .logs(let report):
            try container.encode(ValueType.logs, forKey: .type)
            try container.encode(report.sessions, forKey: .sessions)
        case .legacyHTML(let value):
            try container.encode(ValueType.legacyHTML, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ValueType.self, forKey: .type)

        switch type {
        case .table:
            self = .table(try container.decode([DiagnosticsReportTableRow].self, forKey: .rows))
        case .text:
            self = .text(try container.decode(String.self, forKey: .value))
        case .preformatted:
            self = .preformatted(try container.decode(String.self, forKey: .value))
        case .logs:
            self = .logs(DiagnosticsLogReport(sessions: try container.decode([DiagnosticsLogSession].self, forKey: .sessions)))
        case .legacyHTML:
            self = .legacyHTML(try container.decode(String.self, forKey: .value))
        }
    }
}

struct DiagnosticsReportTableRow: Codable, Sendable {
    let key: String
    let value: String
}

extension Diagnostics {
    var reportDocumentValue: DiagnosticsReportDocumentValue {
        if let logs = self as? DiagnosticsLogReport {
            return .logs(logs)
        }

        if let table = self as? [String: String] {
            return .table(table.sorted(by: { $0.key < $1.key }).map { DiagnosticsReportTableRow(key: $0.key, value: $0.value) })
        }

        if let keyValuePairs = self as? KeyValuePairs<String, String> {
            return .table(keyValuePairs.map { DiagnosticsReportTableRow(key: $0.key, value: $0.value) })
        }

        if let directoryTree = self as? DirectoryTreeNode {
            return .preformatted(String(describing: directoryTree))
        }

        if let text = self as? String {
            return .text(text)
        }

        return .legacyHTML(html())
    }
}

extension DiagnosticsReportDocument {
    var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard
            let data = try? encoder.encode(self),
            let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return string
    }
}
