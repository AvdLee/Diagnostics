//
//  DiagnosticsReportFilter.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 10/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import Foundation

public protocol DiagnosticsReportFilter {
    /// Filters the input `Diagnostics` value. Can be used to remove sensitive data.
    /// - Parameter diagnostics: The `Diagnostics` value to use for input in the filter.
    /// Returns: Any type of `Diagnostics` but possibly filtered.
    static func filter(_ diagnostics: Diagnostics) -> Diagnostics
}
