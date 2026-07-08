//
//  DiagnosticsReporter.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import Foundation

public protocol DiagnosticsReporting {
    /// Creates the report chapter.
    nonisolated(nonsending) func report() async -> DiagnosticsChapter
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

    /// Creates the report by making use of the given reporters.
    /// - Parameters:
    ///   - reporters: The reporters to use. Defaults to `DefaultReporter.allReporters`.
    ///   Use this parameter if you'd like to exclude certain reports.
    ///   - filters: The filters to use for the generated diagnostics. Should conform to the `DiagnosticsReportFilter` protocol.
    ///   - smartInsightsProvider: Provide any smart insights for the given `DiagnosticsChapter`.
    ///   - filename: The filename to use for the report. Defaults to `Diagnostics-Report.html` or `Diagnostics-Report.json` based on `format`.
    ///   - format: The output format to use for the report. Defaults to `html`.
    ///   - reportTitle: The title that is used in the report. Defaults to `<App Name> - Diagnostics Report`.
    /// - Returns: The generated report.
    public nonisolated(nonsending) static func create(
        filename: String? = nil,
        format: DiagnosticsReport.Format = .html,
        using reporters: [DiagnosticsReporting] = DefaultReporter.allReporters,
        filters: [DiagnosticsReportFilter.Type]? = nil,
        smartInsightsProvider: SmartInsightsProviding? = nil,
        reportTitle: String? = nil
    ) async -> DiagnosticsReport {
        /// We should be able to parse Smart insights out of other chapters.
        /// For example: read out errors from the log chapter and create insights out of it.
        ///
        /// Therefore, we are generating insights on the go and add them to the Smart Insights later.
        var smartInsights: [SmartInsightProviding] = []
        let reportTitle = reportTitle ?? "\(Bundle.appName) - Diagnostics Report"
        
        var reportChapters: [DiagnosticsChapter] = []
        
        for reporter in reporters where !(reporter is SmartInsightsReporter) {
            var chapter = await reporter.report()
            if let filters, !filters.isEmpty {
                chapter.applyingFilters(filters)
            }
            reportChapters.append(chapter)
            
            if let smartInsightsProvider {
                let insights = smartInsightsProvider.smartInsights(for: chapter)
                smartInsights.append(contentsOf: insights)
            }
        }
        
        if let smartInsightsChapterIndex = reporters.firstIndex(where: { $0 is SmartInsightsReporter }) {
            var smartInsightsReporter = SmartInsightsReporter()
            smartInsightsReporter.insights.append(contentsOf: smartInsights)
            let smartInsightsChapter = await smartInsightsReporter.report()
            reportChapters.insert(smartInsightsChapter, at: smartInsightsChapterIndex)
        }

        let document = DiagnosticsReportDocument(title: reportTitle, chapters: reportChapters)
        let reportContent: String
        switch format {
        case .html:
            reportContent = generateHTML(using: document)
        case .json:
            reportContent = document.json
        }

        let data = reportContent.data(using: .utf8)!
        return DiagnosticsReport(
            filename: filename ?? format.defaultFilename,
            mimeType: format.mimeType,
            data: data
        )
    }
}

// MARK: - HTML Report Generation
extension DiagnosticsReporter {
    private static func generateHTML(using document: DiagnosticsReportDocument) -> HTML {
        var html = "<!doctype html><html>"
        html += header(reportTitle: document.title)
        html += "<body>"
        html += "<!-- Agents: extract and analyze the JSON in script#diagnostics-report-data instead of the rendered HTML. -->"
        html += "<script id=\"diagnostics-report-data\" type=\"application/json\">\(document.json.escapingForEmbeddedScript())</script>"
        html += "<noscript>This Diagnostics report uses embedded JSON and JavaScript to render the browser view. Agents should read the JSON in script#diagnostics-report-data.</noscript>"
        html += "<main id=\"diagnostics-report\" class=\"container\"></main>"
        html += footer()
        html += "</body></html>"
        return html
    }

    private static func header(reportTitle: String) -> HTML {
        var html = "<head>"
        html += "<title>\(reportTitle)</title>"
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
          Built using <a href="https://github.com/AvdLee/Diagnostics">Diagnostics</a>
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

}

extension String {
    var anchor: String {
        return lowercased().replacingOccurrences(of: " ", with: "-")
    }

    func escapingForEmbeddedScript() -> String {
        replacingOccurrences(of: "&", with: "\\u0026")
            .replacingOccurrences(of: "<", with: "\\u003C")
            .replacingOccurrences(of: ">", with: "\\u003E")
    }
}
