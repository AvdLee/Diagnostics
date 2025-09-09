//
//  HTMLEncoding.swift
//  Diagnostics
//
//  Created by David Steppenbeck on 2020/02/26.
//  Copyright © 2020 Antoine van der Lee. All rights reserved.
//

import Foundation

protocol HTMLEncoding {
    func addingHTMLEncoding() -> HTML
}

extension String: HTMLEncoding {

    /// Encodes entities to be displayed correctly in the final HTML report.
    func addingHTMLEncoding() -> HTML {
        return replacingOccurrences(of: "<", with: "&lt;")
                   .replacingOccurrences(of: ">", with: "&gt;")
    }
}
