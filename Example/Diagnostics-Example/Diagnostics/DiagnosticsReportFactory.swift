//
//  DiagnosticsReportFactory.swift
//  Diagnostics-Example
//
//  Created by A.J. van der Lee on 30/06/2025.
//

import Diagnostics
import Foundation

struct DiagnosticsReportFactory {
    static func make() -> DiagnosticsReport {
        /// Create the report.
        var reporters = DiagnosticsReporter.DefaultReporter.allReporters
        reporters.insert(CustomReporter(), at: 1)

        let documentsURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let directoryTreesReporter = DirectoryTreesReporter(
            trunks: [
                Directory(url: documentsURL)
            ]
        )
        reporters.insert(directoryTreesReporter, at: 2)

        let report = DiagnosticsReporter.create(
            using: reporters,
            filters: [
                DiagnosticsDictionaryFilter.self,
                DiagnosticsStringFilter.self
            ],
            smartInsightsProvider: SmartInsightsProvider()
        )
        return report
    }
}
