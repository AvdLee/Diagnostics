//
//  LogsTrimmerTests.swift
//  
//
//  Created by Antoine van der Lee on 01/03/2024.
//
//  swiftlint:disable line_length

@testable import Diagnostics
import XCTest

final class LogsTrimmerTests: XCTestCase {

    /// It should trim the oldest line and skip session headers.
    func testTrimmingSessionsSingleLine() {
        let lineToTrim = """
        <p class="system"><span class="log-date">2024-02-20 10:33:47</span><span class="log-separator"> | </span><span class="log-message">SYSTEM: 2024-02-20 10:33:47.086 Collect[32949:1669571] Reachability Flag Status: -R t------ reachabilityStatusForFlags</span></p>
        """
        
        let input = """
        <summary><div class="session-header"><p><span>Date: </span>2024-02-20 10:33:47</p><p><span>System: </span>iOS 16.3</p><p><span>Locale: </span>en-GB</p><p><span>Version: </span>6.2.8 (17000)</p></div></summary>
        \(lineToTrim)
        <p class="system"><span class="log-date">2024-02-20 10:33:47</span><span class="log-separator"> | </span><span class="log-message">SYSTEM: 2024-02-20 10:33:47.101 Collect[32949:1669571] [Firebase/Crashlytics] Version 8.15.0</span></p>
        """

        let expectedOutput = input.replacingOccurrences(of: lineToTrim, with: "")
        
        var inputData = Data(input.utf8)
        let trimmer = LogsTrimmer(
            numberOfLinesToTrim: 1
        )

        trimmer.trim(data: &inputData)

        let outputString = String(data: inputData, encoding: .utf8)
        XCTAssertEqual(outputString, expectedOutput)
    }

    /// It should trim the oldest lines and skip session headers.
    func testTrimmingSessionsMultipleLines() {
        let expectedOutput = """
        <summary><div class="session-header"><p><span>Date: </span>2024-02-20 10:33:47</p><p><span>System: </span>iOS 16.3</p><p><span>Locale: </span>en-GB</p><p><span>Version: </span>6.2.8 (17000)</p></div></summary>
        """

        var input = expectedOutput
        input += """
        <p class="system"><span class="log-date">2024-02-20 10:33:47</span><span class="log-separator"> | </span><span class="log-message">SYSTEM: 2024-02-20 10:33:47.086 Collect[32949:1669571] Reachability Flag Status: -R t------ reachabilityStatusForFlags</span></p>
        <p class="system"><span class="log-date">2024-02-20 10:33:47</span><span class="log-separator"> | </span><span class="log-message">SYSTEM: 2024-02-20 10:33:47.101 Collect[32949:1669571] [Firebase/Crashlytics] Version 8.15.0</span></p>
        """

        var inputData = Data(input.utf8)
        let trimmer = LogsTrimmer(
            numberOfLinesToTrim: 10
        )

        trimmer.trim(data: &inputData)

        let outputString = String(data: inputData, encoding: .utf8)
        XCTAssertEqual(outputString, expectedOutput)
    }
}
//  swiftlint:enable line_length
