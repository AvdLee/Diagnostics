//
//  AppSystemMetadataReporterTests.swift
//  DiagnosticsTests
//
//  Created by Antoine van der Lee on 03/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

@testable import Diagnostics
import XCTest

final class AppSystemMetadataReporterTests: XCTestCase {

    /// It should correctly add the metadata.
    func testMetadata() {
        let metadata = AppSystemMetadataReporter().report().diagnostics as! [String: String]

        XCTAssertEqual(
            metadata[AppSystemMetadataReporter.MetadataKey.appName.rawValue],
            Bundle.appName
        )
        XCTAssertEqual(
            metadata[AppSystemMetadataReporter.MetadataKey.appVersion.rawValue],
            "\(Bundle.appVersion) (\(Bundle.appBuildNumber))"
        )
        XCTAssertEqual(
            metadata[AppSystemMetadataReporter.MetadataKey.appLanguage.rawValue],
            "en"
        )

        AppSystemMetadataReporter.MetadataKey.allCases.forEach { key in
            XCTAssertNotNil(metadata[key.rawValue], "Metadata not found for \(key).")
        }
    }
}
