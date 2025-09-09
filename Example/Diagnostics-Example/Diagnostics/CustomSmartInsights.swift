//
//  CustomSmartInsights.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 10/02/2022.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import Diagnostics
import Foundation

struct SmartInsightsProvider: SmartInsightsProviding {
    func smartInsights(for chapter: DiagnosticsChapter) -> [any SmartInsightProviding] {
        guard let html = chapter.diagnostics as? HTML else { return [] }
        if html.errorLogs.contains(where: { $0.contains("AppDelegate.ExampleLocalizedError") }) {
            return [
                SmartInsight(
                    name: "Localized data",
                    result: .warn(message: "An error was found regarding missing localisation.")
                )
            ]
        }
        return []
    }
}
