//
//  DiagnosticsChapter.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 10/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import Foundation

/// Defines a Diagnostics Chapter which will end up in the report as HTML.
public struct DiagnosticsChapter: Sendable {

    /// The title of the diagnostics report which will also be used as HTML anchor.
    public let title: String

    /// The `Diagnostics` to show in the chapter.
    public internal(set) var diagnostics: Diagnostics

    /// Whether the title should be visibly shown.
    public let shouldShowTitle: Bool

    /// An optional HTML formatter to customize the HTML format. `diagnostics.html()` will be used if this formatter is set to `nil`,
    public let formatter: HTMLFormatting.Type?

    public init(title: String, diagnostics: Diagnostics, shouldShowTitle: Bool = true, formatter: HTMLFormatting.Type? = nil) {
        self.title = title
        self.diagnostics = diagnostics
        self.shouldShowTitle = shouldShowTitle
        self.formatter = formatter
    }
}

extension DiagnosticsChapter {
    mutating func applyingFilters(_ filters: [DiagnosticsReportFilter.Type]) {
        filters.forEach { reportFilter in
            diagnostics = reportFilter.filter(diagnostics)
        }
    }
}
