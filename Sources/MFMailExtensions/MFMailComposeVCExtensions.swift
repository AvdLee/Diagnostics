//
//  MFMailComposeVCExtensions.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

#if canImport(MessageUI)
import MessageUI

public extension MFMailComposeViewController {

    /// Adds the given diagnostics report as an attachment to the composing mail.
    /// - Parameter report: The report to add as an attachment.
    func addDiagnosticReport(_ report: DiagnosticsReport) {
        addAttachmentData(report.data, mimeType: report.mimeType.rawValue, fileName: report.filename)
    }

}
#endif
