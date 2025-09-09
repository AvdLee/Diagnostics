//
//  DiagnosticsReport.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import Foundation

#if os(OSX)
import AppKit
#endif

/// The actual diagnostics report containing the compiled data of all reporters.
public struct DiagnosticsReport: Sendable {
    public enum MimeType: String, Sendable {
        case html = "text/html"
    }

    /// The file name to use for the report.
    public let filename: String

    /// The MIME type of the report. Defaults to `html`.
    public let mimeType: MimeType = .html

    /// The data representation of the diagnostics report.
    public let data: Data
}

public extension DiagnosticsReport {
    private var userPath: String {
        let simulatorPath = (NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true) as [String]).first!
        let simulatorPathComponents = URL(string: simulatorPath)!.pathComponents.prefix(3).filter { $0 != "/" }
        let userPath = simulatorPathComponents.joined(separator: "/")
        return userPath
    }
    
    /// This method can be used for debugging purposes to save the report to a `Diagnostics` folder on desktop.
    #if os(iOS)
    func saveToDesktop() {
        let folderPath = "/\(userPath)/Desktop/Diagnostics/"
        try? FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
        let filePath = folderPath + filename
        save(to: filePath)
    }
    #elseif os(OSX)
    @MainActor
    func saveToDesktop() {
        Task { @MainActor in
            let folderPath = "/\(userPath)/Desktop/"
            await saveUsingPanel(initialDirectoryPath: folderPath, filename: filename)
        }
    }
    #endif

    private func save(to filePath: String) {
        guard FileManager.default.createFile(
            atPath: filePath,
            contents: data,
            attributes: [FileAttributeKey.type: mimeType.rawValue]
        ) else {
            print("Diagnostics Report could not be saved to: \(filePath)")
            return
        }

        print("Diagnostics Report saved to: \(filePath)")
    }

#if os(OSX)
    @MainActor
    private func saveUsingPanel(initialDirectoryPath: String, filename: String) async {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.directoryURL = URL(string: initialDirectoryPath)
        savePanel.allowedContentTypes = [.html]
        savePanel.nameFieldStringValue = filename
        savePanel.title = "Save Diagnostics Report"
        savePanel.message = "Save the Diagnostics report to the chosen location."
        savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        let result = await savePanel.begin()
        guard result == .OK, let targetURL = savePanel.url else {
            print("Saving Diagnostics report cancelled or failed")
            return
        }
        self.save(to: targetURL.path)
        NSWorkspace.shared.activateFileViewerSelecting([targetURL])
    }
#endif
}
