//
//  Device.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import Foundation
#if os(macOS)
import AppKit
import SystemConfiguration
#else
import UIKit
#endif

enum Device {
    static var systemName: String {
        #if os(macOS)
        return SCDynamicStoreCopyLocalHostName(nil) as String? ?? "Unknown"
        #elseif os(iOS)
        return "iOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #else
        return "Unknown"
        #endif
    }

    static var systemVersion: String {
        ProcessInfo().operatingSystemVersionString
    }

    static var freeDiskSpace: ByteCountFormatter.Units.GigaBytes {
        ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }

    static var totalDiskSpace: ByteCountFormatter.Units.GigaBytes {
        ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }

    static var totalDiskSpaceInBytes: ByteCountFormatter.Units.Bytes {
        guard let space = try? URL(fileURLWithPath: NSHomeDirectory() as String)
            .resourceValues(forKeys: [URLResourceKey.volumeTotalCapacityKey])
            .volumeTotalCapacity else {
            return 0
        }
        return Int64(space)
    }

    static var freeDiskSpaceInBytes: ByteCountFormatter.Units.Bytes {
        guard let space = try? URL(fileURLWithPath: NSHomeDirectory() as String)
            .resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForOpportunisticUsageKey])
            .volumeAvailableCapacityForOpportunisticUsage else {
            return 0
        }
        return space
    }
}
