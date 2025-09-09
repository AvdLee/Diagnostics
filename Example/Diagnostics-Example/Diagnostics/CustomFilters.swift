//
//  CustomFilter.swift
//  Diagnostics-Example
//
//  Created by Antoine van der Lee on 10/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import Diagnostics
import Foundation

struct DiagnosticsDictionaryFilter: DiagnosticsReportFilter {

    // This demonstrates how a filter can be used to filter out sensible data.
    static func filter(_ diagnostics: any Diagnostics) -> any Diagnostics {
        guard let dictionary = diagnostics as? [String: Any] else { return diagnostics }
        return dictionary.filter { keyValue -> Bool in
            if keyValue.key == "App Display Name" {
                // Filter out the key with the value "App Display Name"
                return false
            } else if keyValue.key == "AppleLanguages" {
                // Filter out a user defaults key.
                return false
            }
            return true
        }
    }
}

struct DiagnosticsStringFilter: DiagnosticsReportFilter {
    static func filter(_ diagnostics: any Diagnostics) -> any Diagnostics {
        guard let string = diagnostics as? String else { return diagnostics }
        /// This filter just demonstrates the fact that you can replace sensible values from a `String`.
        return string.replacingOccurrences(of: "Support team", with: "Amazing Support team")
    }
}
