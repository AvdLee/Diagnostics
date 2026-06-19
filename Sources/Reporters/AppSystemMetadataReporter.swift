//
//  AppSystemMetadataReporter.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

#if canImport(CoreTelephony)
    import CoreTelephony
#endif

import Foundation

/// Reports App and System specific metadata like OS and App version.
public struct AppSystemMetadataReporter: DiagnosticsReporting {

    public enum MetadataKey: String, CaseIterable {
        case appName = "App name"
        case appDisplayName = "App Display Name"
        case appVersion = "App version"
        case device = "Device"
        case system = "System"
        case freeSpace = "Free space"
        case deviceLanguage = "Device Language"
        case appLanguage = "App Language"

        #if os(iOS) && !targetEnvironment(macCatalyst)
        case cellularAllowed = "Cellular Allowed"
        #endif
    }

    static let hardwareName: [String: String] = [
        "iPhone7,1": "iPhone 6 Plus",
        "iPhone7,2": "iPhone 6",
        "iPhone8,1": "iPhone 6s",
        "iPhone8,2": "iPhone 6s Plus",
        "iPhone8,4": "iPhone SE",
        "iPhone9,1": "iPhone 7",
        "iPhone9,2": "iPhone 7 Plus",
        "iPhone9,3": "iPhone 7",
        "iPhone9,4": "iPhone 7 Plus",
        "iPhone10,1": "iPhone 8",
        "iPhone10,2": "iPhone 8 Plus",
        "iPhone10,3": "iPhone X",
        "iPhone10,4": "iPhone 8",
        "iPhone10,5": "iPhone 8 Plus",
        "iPhone10,6": "iPhone X",
        "iPhone11,2": "iPhone XS",
        "iPhone11,4": "iPhone XS Max",
        "iPhone11,6": "iPhone XS Max",
        "iPhone11,8": "iPhone XR",
        "iPhone12,1": "iPhone 11",
        "iPhone12,3": "iPhone 11 Pro",
        "iPhone12,5": "iPhone 11 Pro Max",
        "iPhone12,8": "iPhone SE (2nd generation)",
        "iPhone13,1": "iPhone 12 mini",
        "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro",
        "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,4": "iPhone 13 mini",
        "iPhone14,5": "iPhone 13",
        "iPhone14,6": "iPhone SE (3rd generation)",
        "iPhone14,7": "iPhone 14",
        "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,1": "iPhone 16 Pro",
        "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,3": "iPhone 16",
        "iPhone17,4": "iPhone 16 Plus"
    ]

    let title: String = "App & System Details"
    var diagnostics: [String: String] {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineIdentifier = Mirror(reflecting: systemInfo.machine).children.reduce(into: "") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            identifier += String(UnicodeScalar(UInt8(value)))
        }

        let hardware: String
        if let hardwareName = Self.hardwareName[machineIdentifier] {
            hardware = "\(hardwareName) (Machine ID: \(machineIdentifier))"
        } else {
            hardware = "\(machineIdentifier) (Machine Identifier, not a version number)"
        }

        let system = "\(Device.systemName) \(Device.systemVersion)"

        var metadata: [String: String] = [
            MetadataKey.appName.rawValue: Bundle.appName,
            MetadataKey.appDisplayName.rawValue: Bundle.appDisplayName,
            MetadataKey.appVersion.rawValue: "\(Bundle.appVersion) (\(Bundle.appBuildNumber))",
            MetadataKey.device.rawValue: hardware,
            MetadataKey.system.rawValue: system,
            MetadataKey.freeSpace.rawValue: "\(Device.freeDiskSpace) of \(Device.totalDiskSpace)",
            MetadataKey.deviceLanguage.rawValue: Locale.current.language.languageCode?.identifier ?? "Unknown",
            MetadataKey.appLanguage.rawValue: Locale.preferredLanguages[0]
        ]
        #if os(iOS) && !targetEnvironment(macCatalyst)
            let cellularData = CTCellularData()
            metadata[MetadataKey.cellularAllowed.rawValue] = "\(cellularData.restrictedState)"
        #endif
        return metadata
    }

    public func report() -> DiagnosticsChapter {
        return DiagnosticsChapter(title: title, diagnostics: diagnostics)
    }
}

#if os(iOS) && !targetEnvironment(macCatalyst)
extension CTCellularDataRestrictedState: @retroactive CustomStringConvertible {
     public var description: String {
        switch self {
        case .restricted:
            return "Restricted"
        case .notRestricted:
            return "Not restricted"
        default:
            return "Unknown"
        }
    }
}
#endif
