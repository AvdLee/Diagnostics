//
//  HTML+LoggableCSSClass.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 10/02/2022.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import Foundation

extension HTML {
    func linesForCSSClass(_ htmlClass: LoggableCSSClass) -> [String] {
        components(separatedBy: .newlines)
            .filter { htmlLine in
                htmlLine.hasPrefix("<p class=\"\(htmlClass.rawValue)\">")
            }
    }
}

public extension HTML {
    var errorLogs: [String] { linesForCSSClass(.error) }
    var debugLogs: [String] { linesForCSSClass(.debug) }
    var systemLogs: [String] { linesForCSSClass(.system) }
}
