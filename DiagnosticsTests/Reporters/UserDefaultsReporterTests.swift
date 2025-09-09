//
//  UserDefaultsReporterTests.swift
//  DiagnosticsTests
//
//  Created by Antoine van der Lee on 03/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

@testable import Diagnostics
import XCTest

final class UserDefaultsReporterTests: XCTestCase {

    /// It should show the user defaults in the report.
    func testReportUserDefaults() {
        let userDefaults = UserDefaults.standard

        let expectedValue1 = UUID().uuidString
        let key1 = "test_key_1"
        userDefaults.set(expectedValue1, forKey: key1)

        let expectedValue2 = UUID().uuidString
        let key2 = "test_key_2"
        userDefaults.set(expectedValue2, forKey: key2)

        let unexpectedValue = UUID().uuidString
        let unexpectedKey = "unexpected_key"
        userDefaults.set(unexpectedValue, forKey: unexpectedKey)

        let diagnostics = UserDefaultsReporter(
            userDefaults: userDefaults,
            keys: [key1, key2]
        ).report().diagnostics as! [String: String]

        XCTAssertEqual(diagnostics.count, 2)
        XCTAssertEqual(diagnostics[key1], expectedValue1)
        XCTAssertEqual(diagnostics[key2], expectedValue2)
        XCTAssertNil(diagnostics[unexpectedKey])
    }

}
