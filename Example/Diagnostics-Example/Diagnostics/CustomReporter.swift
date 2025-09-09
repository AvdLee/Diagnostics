//
//  CustomReporter.swift
//  Diagnostics-Example
//
//  Created by Antoine van der Lee on 04/12/2019.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import Diagnostics
import Foundation

enum Session {
    /// A fake property to demonstrate the custom reporter.
    static var isLoggedIn = false
}

/// An example Custom Reporter.
struct CustomReporter: DiagnosticsReporting {
    func report() -> DiagnosticsChapter {
        let diagnostics: [String: String] = [
            "Logged In": Session.isLoggedIn.description
        ]

        return DiagnosticsChapter(title: "My custom report", diagnostics: diagnostics)
    }
}
