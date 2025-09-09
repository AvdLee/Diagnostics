//
//  DeviceStorageInsightTests.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 10/02/2022.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import XCTest
@testable import Diagnostics

final class DeviceStorageInsightTests: XCTestCase {

    func testLowOnStorage() {
        let insight = DeviceStorageInsight(freeDiskSpace: 800 * 1000 * 1000, totalDiskSpace: "100GB")
        XCTAssertEqual(insight.result, .warn(message: "The user is low on storage (800 MB of 100GB left)"))
    }

    func testEnoughStorage() {
        let insight = DeviceStorageInsight(freeDiskSpace: 8000 * 1000 * 1000, totalDiskSpace: "100GB")
        XCTAssertEqual(insight.result, .success(message: "The user has enough storage (8 GB of 100GB left)"))
    }

}
