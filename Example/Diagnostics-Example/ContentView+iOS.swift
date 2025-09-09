//
//  ContentView.swift
//  Diagnostics-Example
//
//  Created by A.J. van der Lee on 30/06/2025.
//

#if !os(macOS)

import SwiftUI
public import Diagnostics
import MessageUI

struct ContentView_iOS: View {
    
    @State private var presentDiagnosticsSheet = false
    @State private var report: DiagnosticsReport?
    
    var body: some View {
        Form {
            Button("Create crash") {
                performCrash()
            }
            Button("Send Diagnostics") {
                Task {
                    let report = await DiagnosticsReportFactory.make()
                    #if targetEnvironment(simulator)
                        /// For debugging purposes you can save the report to desktop when testing on the simulator.
                        /// This allows you to iterate fast on your report.
                        report.saveToDesktop()
                    #else
                        self.report = report
                    #endif
                }
            }
        }.diagnosticsReportSheet(report: $report)
    }
}

#Preview {
    ContentView_iOS()
}

extension DiagnosticsReport: @retroactive Identifiable {
    public var id: String { filename + String(data: data, encoding: .utf8)! }
}

extension View {
    @ViewBuilder
    func diagnosticsReportSheet(report: Binding<DiagnosticsReport?>) -> some View {
        if MFMailComposeViewController.canSendMail() {
            self.sheet(item: report) { report in
                MailComposerViewController(
                    recipients: ["support@yourcompany.com"],
                    subject: "Diagnostics Report",
                    messageBody: "An issue in the app is making me crazy, help!",
                    report: report
                )
            }
        } else {
            self.sheet(item: report) { reportItem in
                ShareSheet(items: [
                    reportItem.writeToTemporaryDirectory()
                ], report: report)
            }
        }
    }
}

extension DiagnosticsReport {
    func writeToTemporaryDirectory() -> URL {
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(self.filename)
        try! self.data.write(to: destinationURL)
        return destinationURL
    }
}

extension View {
    func shareSheet(report: Binding<DiagnosticsReport?>, items: [Any]) -> some View {
        background(
            ShareSheet(items: items, report: report)
        )
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    @Binding var report: DiagnosticsReport?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            report = nil
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct MailComposerViewController: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    var recipients: [String]
    var subject: String
    var messageBody: String
    var report: DiagnosticsReport

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        mailComposer.setToRecipients(recipients)
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(messageBody, isHTML: false)
        mailComposer.addDiagnosticReport(report)
        return mailComposer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposerViewController

        init(_ parent: MailComposerViewController) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
            parent.dismiss()
        }
    }
}


#endif
