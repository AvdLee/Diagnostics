//
//  UpdateAvailableInsightTests.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 10/02/2022.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import XCTest
@testable import Diagnostics
import Combine

final class UpdateAvailableInsightTests: XCTestCase {

    let exampleError = NSError(domain: UUID().uuidString, code: -1, userInfo: nil)
    let sampleBundleIdentifier = "com.wetransfer.example.app"

    func testReturningNilIfNoBundleIdentifier() {
        XCTAssertNil(UpdateAvailableInsight(bundleIdentifier: nil))
    }

    func testReturningNilIfNoAppMetadataAvailable() async {
        let expectation = expectation(description: #function)
        func appMetadataCompletion() -> Result<AppMetadataResults, Error> {
            expectation.fulfill()
            return Result.failure(exampleError)
        }
        let insight = UpdateAvailableInsight(bundleIdentifier: sampleBundleIdentifier, appMetadataCompletion: appMetadataCompletion)
        let result = await insight?.generateResult()
        XCTAssertNil(result)
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testUserIsOnTheSameVersion() async {
        let expectation = expectation(description: #function)
        let appMetadata = AppMetadataResults(results: [.init(version: "1.0.0")])
        func appMetadataCompletion() -> Result<AppMetadataResults, Error> {
            expectation.fulfill()
            return Result.success(appMetadata)
        }

        let insight = UpdateAvailableInsight(bundleIdentifier: sampleBundleIdentifier, currentVersion: "1.0.0", appMetadataCompletion: appMetadataCompletion)
        let result = await insight?.generateResult()
        XCTAssertEqual(result, .success(message: "The user is using the latest app version 1.0.0"))
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testUserIsOnANewerVersion() async {
        let expectation = expectation(description: #function)
        let appMetadata = AppMetadataResults(results: [.init(version: "1.0.0")])
        func appMetadataCompletion() -> Result<AppMetadataResults, Error> {
            expectation.fulfill()
            return Result.success(appMetadata)
        }

        let insight = UpdateAvailableInsight(bundleIdentifier: sampleBundleIdentifier, currentVersion: "2.0.0", appMetadataCompletion: appMetadataCompletion)
        let result = await insight?.generateResult()
        XCTAssertEqual(result, .success(message: "The user is using a newer version 2.0.0"))
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testUserIsOnAnOlderVersion() async {
        let expectation = expectation(description: #function)
        let appMetadata = AppMetadataResults(results: [.init(version: "2.0.0")])
        func appMetadataCompletion() -> Result<AppMetadataResults, Error> {
            expectation.fulfill()
            return Result.success(appMetadata)
        }

        let insight = UpdateAvailableInsight(bundleIdentifier: sampleBundleIdentifier, currentVersion: "1.0.0", appMetadataCompletion: appMetadataCompletion)
        let result = await insight?.generateResult()
        XCTAssertEqual(result, .warn(message: "The user could update to 2.0.0"))
        await fulfillment(of: [expectation], timeout: 1)
    }
}
