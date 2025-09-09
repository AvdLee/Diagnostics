//
//  GeneralInfoReporterTests.swift
//  DiagnosticsTests
//
//  Created by Antoine van der Lee on 03/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import XCTest
@testable import Diagnostics

final class GeneralInfoReporterTests: XCTestCase {

    /// It should include the title in the report.
    func testTitle() {
        XCTAssertEqual(GeneralInfoReporter().report().title, "Information")
    }

    func testDescription() {
        let reporter = GeneralInfoReporter()
        let diagnostics = reporter.report().diagnostics as! String
        XCTAssertEqual(diagnostics, reporter.description)
    }

}
