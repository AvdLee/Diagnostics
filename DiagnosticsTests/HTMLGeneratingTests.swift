//
//  HTMLGeneratingTests.swift
//  DiagnosticsTests
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import XCTest
@testable import Diagnostics

final class HTMLGeneratingTests: XCTestCase {

    /// It should generate HTML for diagnostic chapters correctly.
    func testDiagnosticsChapterHTML() {
        let chapter = DiagnosticsChapter(title: "TITLE", diagnostics: "CONTENT")
        let expectedHTML = "<div class=\"chapter\"><span class=\"anchor\" id=\"\(chapter.title.lowercased())\"></span><h3>\(chapter.title)</h3><div class=\"chapter-content\">\(chapter.diagnostics.html())</div></div>"
        XCTAssertEqual(chapter.html(), expectedHTML)
    }

    /// It should correctly transform a Dictionary to HTML.
    func testDictionaryHTML() {
        let dict = ["App Name": "RocketSim"]
        let expectedHTML = "<table><tr><th>\(dict.keys.first!)</th><td>\(dict.values.first!)</td></tr></table>"
        XCTAssertEqual(dict.html(), expectedHTML)
    }

    /// It should correctly transform a Dictionary to HTML.
    func testKeyValuePairsHTML() {
        let dict: KeyValuePairs<String, String> = ["App Name": "RocketSim"]
        let expectedHTML = "<table><tr><th>\(dict.first!.key)</th><td>\(dict.first!.value)</td></tr></table>"
        XCTAssertEqual(dict.html(), expectedHTML)
    }

    /// It should correctly transform a String to HTML.
    func testStringHTML() {
        let value = "CONTENT"
        let expectedHTML = "CONTENT"
        XCTAssertEqual(value.html(), expectedHTML)
    }

    /// It should use a custom formatter if set.
    func testCustomFormatter() {
        let chapter = DiagnosticsChapter(title: UUID().uuidString, diagnostics: UUID().uuidString, formatter: MockHTMLFormatter.self)
        XCTAssertTrue(chapter.html().contains("MOCKED"))
    }

}

struct MockHTMLFormatter: HTMLFormatting {
    static func format(_ diagnostics: Diagnostics) -> HTML {
        return "MOCKED"
    }
}
