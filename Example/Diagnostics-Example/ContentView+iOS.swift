//
//  ContentView.swift
//  Diagnostics-Example
//
//  Created by A.J. van der Lee on 30/06/2025.
//

#if !os(macOS)

import SwiftUI
import Diagnostics
import MessageUI

struct ContentView_iOS: View {
    
    @State private var presentDiagnosticsSheet = false
    
    var body: some View {
        Form {
            Button("Create crash") {
                performCrash()
            }
            Button("Send Diagnostics") {
                #if targetEnvironment(simulator)
                    /// For debugging purposes you can save the report to desktop when testing on the simulator.
                    /// This allows you to iterate fast on your report.
                    let report = DiagnosticsReportFactory.make()
                    report.saveToDesktop()
                #else
                    presentDiagnosticsSheet = true
                #endif
            }
        }.diagnosticsReportSheet(isPresented: $presentDiagnosticsSheet)
    }
}

#Preview {
    ContentView_iOS()
}

extension View {
    @ViewBuilder
    func diagnosticsReportSheet(isPresented: Binding<Bool>) -> some View {
        let report = DiagnosticsReportFactory.make()
        if MFMailComposeViewController.canSendMail() {
            self.sheet(isPresented: isPresented) {
                MailComposerViewController(
                    recipients: ["support@yourcompany.com"],
                    subject: "Diagnostics Report",
                    messageBody: "An issue in the app is making me crazy, help!",
                    report: report
                )
            }
        } else {
            self.sheet(isPresented: isPresented) {
                ShareSheet(items: [
                    report.writeToTemporaryDirectory()
                ], isPresented: isPresented)
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
    func shareSheet(isPresented: Binding<Bool>, items: [Any]) -> some View {
        background(
            ShareSheet(items: items, isPresented: isPresented)
        )
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            isPresented = false
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

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}


#endif
