//
//  DirectoryTreesReporter.swift
//  
//
//  Created by Antoine van der Lee on 27/07/2022.
//

import Foundation

public struct Directory: Sendable {
    let url: URL
    let customisedName: String?
    let maxDepth: Int
    let maxLength: Int
    let includeHiddenFiles: Bool
    let includeSymbolicLinks: Bool
    let printFullPath: Bool

    /// Directory/Group to be diagnosed
    /// - Parameters:
    ///   - url: location of resource
    ///   - customisedName: name to use in report instead of unique string url.
    ///   - maxDepth: The max depth of directories to visit. Defaults to `.max`.
    ///   - maxLength: The max length of nodes in a directory to handle. Defaults to `10`.
    ///   - includeHiddenFiles: Whether hidden files should be captured. Defaults to `false`.
    ///   - includeSymbolicLinks: Whether symbolic links should be captured. Defaults to `false`.
    ///   - printFullPath: Whether the full path of the node should be printed or just the name. Defaults to `false`.
    public init(url: URL,
                customisedName: String? = nil,
                maxDepth: Int = .max,
                maxLength: Int = 10,
                includeHiddenFiles: Bool = false,
                includeSymbolicLinks: Bool = false,
                printFullPath: Bool = false) {
        self.url = url
        self.customisedName = customisedName
        self.maxDepth = maxDepth
        self.maxLength = maxLength
        self.includeHiddenFiles = includeHiddenFiles
        self.includeSymbolicLinks = includeSymbolicLinks
        self.printFullPath = printFullPath
    }
}

/// Reports a directory tree structure for the given directory urls.
public struct DirectoryTreesReporter: DiagnosticsReporting {
    let trunks: [Directory]

    /// Creates a new reporter for directory trees.
    /// eventually uses the new init(trunk: [Directory])
    /// - Parameters:
    ///   - directories: The directories to create trees for.
    ///   - maxDepth: The max depth of directories to visit. Defaults to `.max`.
    ///   - maxLength: The max length of nodes in a directory to handle. Defaults to `10`.
    ///   - includeHiddenFiles: Whether hidden files should be captured. Defaults to `false`.
    ///   - includeSymbolicLinks: Whether symbolic links should be captured. Defaults to `false`.
    ///   - printFullPath: Whether the full path of the node should be printed or just the name. Defaults to `false`.
    @available(*, deprecated, message: "Use the new init(trunks: [Directory])")
    public init(
        directories: [URL],
        maxDepth: Int = .max,
        maxLength: Int = 10,
        includeHiddenFiles: Bool = false,
        includeSymbolicLinks: Bool = false,
        printFullPath: Bool = false
    ) {
        var newTrunks: [Directory] = []
        directories.forEach { directoryURL in
            newTrunks.append(Directory(url: directoryURL,
                                       maxDepth: maxDepth,
                                       maxLength: maxLength,
                                       includeHiddenFiles: includeHiddenFiles,
                                       includeSymbolicLinks: includeSymbolicLinks,
                                       printFullPath: printFullPath))
        }
        self.init(trunks: newTrunks)
    }

    public init(trunks: [Directory]) {
        self.trunks = trunks
    }

    public func report() -> DiagnosticsChapter {
        var diagnostics = ""

        for trunk in trunks {
            do {
                let trunkName = trunk.customisedName ?? trunk.url.lastPathComponent
                diagnostics.append("<h3>Directory Tree for: \(trunkName)</h3>")

                let tree = try DirectoryTreeFactory(
                    path: trunk.url.path,
                    maxDepth: trunk.maxDepth,
                    maxLength: trunk.maxLength,
                    includeHiddenFiles: trunk.includeHiddenFiles,
                    includeSymbolicLinks: trunk.includeSymbolicLinks
                ).make()

                diagnostics.append("""
                <ul>
                    <li>Number of directories: \(tree.directories.count)</li>
                    <li>Number of files: \(tree.files.count)</li>
                </ul>
                """)
                diagnostics.append("""
                <pre>
                \(tree.prettyString(printFullPath: trunk.printFullPath))
                </pre>
                """)
            } catch {
                diagnostics.append("<p>Failed generating tree: \(error.localizedDescription)</p>")
            }
        }
        return DiagnosticsChapter(title: "Directory Trees", diagnostics: diagnostics, shouldShowTitle: false)
    }
}
