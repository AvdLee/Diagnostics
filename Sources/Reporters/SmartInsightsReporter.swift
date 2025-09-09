//
//  SmartInsightsReporter.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 09/02/2022.
//  Copyright © 2019 WeTransfer. All rights reserved.
//
import Foundation

public enum InsightResult: Equatable {
    case success(message: String)
    case warn(message: String)
    case error(message: String)

    var message: String {
        switch self {
        case .success(let message):
            return "✅ \(message)"
        case .warn(let message):
            return "⚠️ \(message)"
        case .error(let message):
            return "❌ \(message)"
        }
    }
}

/// Provides a smart insights with a given success, error, or warn result.
public protocol SmartInsightProviding {

    /// The name of the smart insight.
    var name: String { get }

    /// Generates the result of this insight, see `InsightResult`.
    nonisolated(nonsending) func generateResult() async -> InsightResult?
}

/// Reports smart insights based on given variables.
public struct SmartInsightsReporter: DiagnosticsReporting {

    let title: String = "Smart Insights"
    var insights: [SmartInsightProviding]

    init() {
        var defaultInsights: [SmartInsightProviding?] = [
            DeviceStorageInsight(),
            UpdateAvailableInsight()
        ]
        #if os(iOS) && !targetEnvironment(macCatalyst)
            defaultInsights.append(CellularAllowedInsight())
        #endif

        insights = defaultInsights.compactMap { $0 }
    }

    public nonisolated(nonsending) func report() async -> DiagnosticsChapter {
        var metadata: [String: String] = [:]
        
        for insight in insights {
            guard let result = await insight.generateResult() else { continue }
            metadata[insight.name] = result.message
        }
        
        return DiagnosticsChapter(title: title, diagnostics: metadata)
    }
}
