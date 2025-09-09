//
//  Mocks.swift
//  DiagnosticsTests
//
//  Created by Antoine van der Lee on 03/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import Diagnostics

struct MockedReporter: DiagnosticsReporting {

    var diagnosticsChapter: DiagnosticsChapter!

    func report() -> DiagnosticsChapter {
        return diagnosticsChapter
    }
}
