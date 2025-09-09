//
//  HTMLGenerating.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import Foundation

public typealias HTML = String

public protocol HTMLGenerating: Sendable {
    func html() -> HTML
}

public protocol HTMLFormatting: Sendable {
    static func format(_ diagnostics: Diagnostics) -> HTML
}

extension Dictionary: HTMLGenerating where Key == String, Value == String {
    public func html() -> HTML {
        var html = "<table>"

        for (key, value) in self.sorted(by: { $0.0 < $1.0 }) {
            html += "<tr><th>\(key.description)</th><td>\(value)</td></tr>"
        }

        html += "</table>"

        return html
    }
}

extension KeyValuePairs: HTMLGenerating where Key == String, Value == String {
    public func html() -> HTML {
        var html = "<table>"

        for (key, value) in self {
            html += "<tr><th>\(key)</th><td>\(value)</td></tr>"
        }

        html += "</table>"

        return html
    }
}

extension String: HTMLGenerating {
    public func html() -> HTML {
        return self
    }
}

extension DirectoryTreeNode: HTMLGenerating {
    public func html() -> HTML {
        return "<pre>\(self)</pre>"
    }
}

extension DiagnosticsChapter: HTMLGenerating {
    public func html() -> HTML {
        var html = "<div class=\"chapter\">"
        html += "<span class=\"anchor\" id=\"\(title.anchor)\"></span>"

        if shouldShowTitle {
            html += "<h3>\(title)</h3>"
        }

        html += "<div class=\"chapter-content\">"

        if let formatter {
            html += formatter.format(diagnostics)
        } else {
            html += diagnostics.html()
        }

        html += "</div></div>"
        return html
    }
}
