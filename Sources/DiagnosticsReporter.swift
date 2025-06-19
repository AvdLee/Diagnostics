//
//  DiagnosticsReporter.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import Foundation

public protocol DiagnosticsReporting {
    /// Creates the report chapter.
    func report() -> DiagnosticsChapter
}

public enum DiagnosticsReporter {

    public enum DefaultReporter: CaseIterable {
        case generalInfo
        case appSystemMetadata
        case smartInsights
        case logs

        public var reporter: DiagnosticsReporting {
            switch self {
            case .generalInfo:
                return GeneralInfoReporter()
            case .appSystemMetadata:
                return AppSystemMetadataReporter()
            case .smartInsights:
                return SmartInsightsReporter()
            case .logs:
                return LogsReporter()
            }
        }

        public static var allReporters: [DiagnosticsReporting] {
            allCases.map { $0.reporter }
        }
    }

    /// The title that is used in the header of the web page of the report.
    static var reportTitle: String = "\(Bundle.appName) - Diagnostics Report"

    /// Creates the report by making use of the given reporters.
    /// - Parameters:
    ///   - reporters: The reporters to use. Defaults to `DefaultReporter.allReporters`.
    ///   Use this parameter if you'd like to exclude certain reports.
    ///   - filters: The filters to use for the generated diagnostics. Should conform to the `DiagnosticsReportFilter` protocol.
    ///   - smartInsightsProvider: Provide any smart insights for the given `DiagnosticsChapter`.
    public static func create(
        filename: String = "Diagnostics-Report.html",
        using reporters: [DiagnosticsReporting] = DefaultReporter.allReporters,
        filters: [DiagnosticsReportFilter.Type]? = nil,
        smartInsightsProvider: SmartInsightsProviding? = nil
    ) -> DiagnosticsReport {
        /// We should be able to parse Smart insights out of other chapters.
        /// For example: read out errors from the log chapter and create insights out of it.
        ///
        /// Therefore, we are generating insights on the go and add them to the Smart Insights later.
        var smartInsights: [SmartInsightProviding] = []

        var reportChapters = reporters
            .filter { ($0 is SmartInsightsReporter) == false }
            .map { reporter -> DiagnosticsChapter in
                var chapter = reporter.report()
                if let filters, !filters.isEmpty {
                    chapter.applyingFilters(filters)
                }
                if let smartInsightsProvider {
                    let insights = smartInsightsProvider.smartInsights(for: chapter)
                    smartInsights.append(contentsOf: insights)
                }

                return chapter
            }

        if let smartInsightsChapterIndex = reporters.firstIndex(where: { $0 is SmartInsightsReporter }) {
            var smartInsightsReporter = SmartInsightsReporter()
            smartInsightsReporter.insights.append(contentsOf: smartInsights)
            let smartInsightsChapter = smartInsightsReporter.report()
            reportChapters.insert(smartInsightsChapter, at: smartInsightsChapterIndex)
        }

        let html = generateHTML(using: reportChapters)
        let data = html.data(using: .utf8)!
        return DiagnosticsReport(filename: filename, data: data)
    }
}

// MARK: - HTML Report Generation
extension DiagnosticsReporter {
    private static func generateHTML(using reportChapters: [DiagnosticsChapter]) -> HTML {
        var html = "<html>"
        html += header()
        html += "<body>"
        html += "<main class=\"container\">"

        html += menu(using: reportChapters)
        html += mainContent(using: reportChapters)

        html += "</main>"
        html += footer()
        html += "</body>"
        return html
    }

    private static func header() -> HTML {
        var html = "<head>"
        html += "<title>\(Bundle.appName) - Diagnostics Report</title>"
        html += style()
        html += scripts()
        html += "<meta charset=\"utf-8\">"
        html += "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
        html += "</head>"
        return html
    }

    //  swiftlint:disable line_length
    private static func footer() -> HTML {
        return """
        <footer>
          Built using <a href="https://github.com/WeTransfer/Diagnostics">Diagnostics</a> by <a href="https://wetransfer.com">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" class="footer-logo">
            <path d="M51.4 46.8c4.6 0 8-1.4 9.9-3.4 1-1.1 2.1-2.8 1.3-4.1-.7-1.1-1.9-1.4-3.3-.7-1.5.7-3.1 1.1-4.8 1.1-1.7 0-3.3-.5-4.6-1.6-1.2-1.2-1.9-2.8-1.8-4.5 0-.4.3-.5.8-.1 1.7 1.1 3.6 1.6 5.6 1.5 4.6 0 8.7-3.1 8.7-7.9 0-5.1-4.8-8.8-12-8.8-8.1 0-14.4 5.2-14.4 14-.1 8.3 5.4 14.5 14.6 14.5zm-33.5-8.6c.9 0 1.4.5 2 1.4l2.6 4.1c1 1.6 1.8 2.7 3.7 2.7s2.8-.8 3.7-2.9c1.4-3.2 2.6-6.6 3.4-10 1.2-4.7 1.7-7.7 1.7-10.1s-.8-3.8-3.4-4.3c-4.5-.7-9.2-1.1-13.8-1-4.6 0-9.2.3-13.8 1-2.6.5-3.4 1.9-3.4 4.3s.5 5.3 1.7 10.1c.9 3.4 2 6.8 3.4 10 .9 2.1 1.8 2.9 3.7 2.9s2.7-1.1 3.7-2.7l2.6-4.1c.9-.9 1.4-1.4 2.2-1.4z"/>
          </svg>
        </a>
        </footer>
        """
    }
    //  swiftlint:enable line_length

    static func style() -> HTML {
        guard let cssURL = Bundle.module.url(forResource: "style.css", withExtension: nil), let css = try? String(contentsOf: cssURL) else {
            return ""
        }
        return "<style>\(css)</style>"
    }

    static func scripts() -> HTML {
        guard
            let scriptsURL = Bundle.module.url(forResource: "functions.js", withExtension: nil),
            let scripts = try? String(contentsOf: scriptsURL) else {
            return ""
        }
        return "<script type=\"text/javascript\">\(scripts)</script>"
    }

    //  swiftlint:disable line_length
    static func menu(using chapters: [DiagnosticsChapter]) -> HTML {
        var html = "<aside class=\"nav-container\"><nav><ul>"
        chapters.forEach { chapter in
            html += "<li><a href=\"#\(chapter.title.anchor)\">\(chapter.title)</a></li>"
        }
        html += "<li><button id=\"expand-sections\">Expand sessions</button></li>"
        html += "<li><button id=\"collapse-sections\">Collapse sessions</button></li>"
        html += "<li><input type=\"checkbox\" id=\"system-logs\" name=\"system-logs\" checked><label for=\"system-logs\">Show system logs</label></li>"
        html += "<li><input type=\"checkbox\" id=\"error-logs\" name=\"error-logs\" checked><label for=\"error-logs\">Show error logs</label></li>"
        html += "<li><input type=\"checkbox\" id=\"debug-logs\" name=\"debug-logs\" checked><label for=\"debug-logs\">Show debug logs</label></li>"
        html += "<li><textarea id="log-filter" placeholder="Regex" rows="3"></textarea></li>"
        html += "<li><button id="filter-btn">Filter</button></li>"
        html += "<li><code>Example OR: <b>error|warning</b></code></li>"
        html += "<li><code>Example AND: <b>(?=.*error)(?=.*timeout)</b></code></li>"
        html += "<li><code>Example Prefix: <b>^[INFO]:</b></code></li>"
        html += "</ul></nav></aside>"
        return html
    }
    //  swiftlint:enable line_length

    static func mainContent(using chapters: [DiagnosticsChapter]) -> HTML {
        var html = "<div class=\"main-content\">"
        html += "<header><h1>\(reportTitle)</h1></header>"
        chapters.forEach { chapter in
            html += chapter.html()
        }
        html += "</div>"
        return html
    }
}

extension String {
    var anchor: String {
        return lowercased().replacingOccurrences(of: " ", with: "-")
    }
}
