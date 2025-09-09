//
//  DeviceStorageInsight.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 09/02/2022.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import Foundation

/// Shows an insight on whether the user has enough storage left or not.
struct DeviceStorageInsight: SmartInsightProviding {

    static let warningThreshold: ByteCountFormatter.Units.Bytes = 1000 * 1000 * 1000 // 1GB

    let name = "Storage"
    let result: InsightResult

    init(
        freeDiskSpace: ByteCountFormatter.Units.Bytes = Device.freeDiskSpaceInBytes,
        totalDiskSpace: ByteCountFormatter.Units.GigaBytes = Device.totalDiskSpace) {
        let lowOnStorage = freeDiskSpace <= Self.warningThreshold
        let freeDiskSpaceString = ByteCountFormatter.string(fromByteCount: freeDiskSpace, countStyle: ByteCountFormatter.CountStyle.decimal)
        let storageStatus = "(\(freeDiskSpaceString) of \(totalDiskSpace) left)"
        if lowOnStorage {
            result = .warn(message: "The user is low on storage \(storageStatus)")
        } else {
            result = .success(message: "The user has enough storage \(storageStatus)")
        }
    }
    
    func generateResult() async -> InsightResult? {
        result
    }
}
