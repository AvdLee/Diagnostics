//
//  BundleExtensions.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import Foundation

extension Bundle {
    static var appName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    }

    static var appDisplayName: String {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""
    }

    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    static var appBuildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}
