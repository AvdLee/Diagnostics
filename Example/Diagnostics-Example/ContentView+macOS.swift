//
//  ContentView+macOS.swift
//  Diagnostics-Example
//
//  Created by A.J. van der Lee on 30/06/2025.
//

#if os(macOS)
import SwiftUI
import Diagnostics
import AppKit

struct ContentView_macOS: View {
    @State private var saveToDesktop = false
    
    /// We only support reporting issues through the native Mac Mail app provider.
    /// Otherwise, macOS might open the browser using sites like outlook.com that won't support
    /// sending attachments.
    private var canSendMail: Bool {
        guard let url = URL(string: "mailto://") else { return false }
        return NSWorkspace.shared.urlForApplication(toOpen: url)?.lastPathComponent == "Mail.app"
    }
    
    var body: some View {
        Form {
            Toggle("Save to desktop", isOn: $saveToDesktop)
            Button("Create crash") {
                performCrash()
            }
            Button("Send Diagnostics") {
                report()
            }
        }
    }
    
    private func report() {

        /// Create the report.
        let report = DiagnosticsReportFactory.make()

        guard !saveToDesktop else {
            report.saveToDesktop()
            return
        }

        guard let service = NSSharingService(named: NSSharingService.Name.composeEmail), canSendMail else {
            handleFailedDiagnosticsReportSending(report)
            return
        }
        service.recipients = ["support@yourcompany.com"]
        service.subject = "Diagnostics Report"

        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Diagnostics-Report.html")

        // remove previous report
        try? FileManager.default.removeItem(at: url)

        do {
            try report.data.write(to: url)
        } catch {
            print("Diagnostics report saving failed with error: \(error)")
        }

        guard service.canPerform(withItems: [url]) else {
            handleFailedDiagnosticsReportSending(report)
            return
        }

        service.perform(withItems: [url])
    }

    private func handleFailedDiagnosticsReportSending(_ report: DiagnosticsReport) {
        NSAlert(
            title: "Can't attached report to your mail client",
            message: "We failed to open your mail app with the report attached.\n\nThe report can now be saved to a preferred location, after which we'd love it if you could mail it to support@yourcompany.com.\n\nThanks!"
        ).runModal()
        report.saveToDesktop()
    }
}

private extension NSAlert {
    convenience init(title: String, message: String) {
        self.init()

        messageText = title
        informativeText = message
        addButton(withTitle: "OK")
    }
}


#endif
