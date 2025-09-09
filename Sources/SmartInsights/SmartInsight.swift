//
//  SmartInsight.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 10/02/2022.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import Foundation

/// A default accessible smart insight to use for quick insights, without the need
/// of creating a custom instance.
public struct SmartInsight: SmartInsightProviding {
    public let name: String
    public let result: InsightResult

    public init(name: String, result: InsightResult) {
        self.name = name
        self.result = result
    }
    
    public func generateResult() async -> InsightResult? {
        result
    }
}
