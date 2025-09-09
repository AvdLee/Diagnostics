//
//  MFMailComposeViewControllerTests.swift
//  DiagnosticsTests
//
//  Created by Antoine van der Lee on 03/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import XCTest
@testable import Diagnostics
#if canImport(MessageUI)
import MessageUI

final class MFMailComposeViewControllerTests: XCTestCase {

    /// It should be able to add a report as an attachment.
    @MainActor
    func testAttachmentAdding() {
        let expectedData = Data()
        let report = DiagnosticsReport(filename: UUID().uuidString, data: expectedData)
        let viewController = MockedMFMailComposeViewController()
        viewController.addDiagnosticReport(report)

        XCTAssertEqual(viewController.attachment, expectedData)
        XCTAssertEqual(viewController.mimeType, DiagnosticsReport.MimeType.html.rawValue)
        XCTAssertEqual(viewController.filename, report.filename)
        
    }
}

private final class MockedMFMailComposeViewController: MFMailComposeViewController {
    private(set) var attachment: Data?
    private(set) var mimeType: String?
    private(set) var filename: String?

    override class func canSendMail() -> Bool {
        return true
    }

    init() {
        super.init(navigationBarClass: nil, toolbarClass: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func addAttachmentData(_ attachment: Data, mimeType: String, fileName filename: String) {
        self.attachment = attachment
        self.mimeType = mimeType
        self.filename = filename
    }
}
#endif
