//
//  DirectoryTreeFactory.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 27/07/2022.
//

import Foundation

/// A Directory Tree factory that creates a tree of directories and files
/// as a collection of `DirectoryTreeNode` instances.
struct DirectoryTreeFactory {
    enum Error: Swift.Error {
        case invalidFileType
        case rootNodeCreationFailed
    }

    /// The path to the root directory.
    let path: String

    /// The max depth of directories to visit.
    var maxDepth: Int = .max

    /// The max length of nodes in a directory to handle.
    var maxLength: Int = 10

    /// Whether hidden files should be captured.
    var includeHiddenFiles = false

    /// Whether symbolic links should be captured.
    var includeSymbolicLinks = false

    /// The file manager to use for operations.
    var fileManager: FileManager = .default

    /// The extraction method to use.
    var nameExtraction: Directory.NameExtraction = .localized

    /// Closure to determine if a directory's contents should be skipped.
    var skipDirectoryContents: @Sendable (_ path: String) -> Bool = { _ in false }

    func make() throws -> DirectoryTreeNode {
        guard let rootNode = try nodeFrom(path: path, depth: 0) else {
            throw Error.rootNodeCreationFailed
        }
        return rootNode
    }

    private func nodeFrom(path: String, depth: Int) throws -> DirectoryTreeNode? {
        guard depth < maxDepth else { return nil }

        let name = switch nameExtraction {
        case .localized: fileManager.displayName(atPath: path)
        case .raw: (path as NSString).lastPathComponent
        }

        guard includeHiddenFiles || !name.starts(with: ".") else {
            return nil
        }

        // Skip expensive operations for directories we don't want to traverse (especially beneficial on iCloud folders).
        if isDirectory(atPath: path) && skipDirectoryContents(path) {
            if isSymbolicLink(atPath: path) {
                guard includeSymbolicLinks else { return nil }
                return .symbolLink(path, name)
            } else {
                return .directory(path, name, [])
            }
        }

        let type = try fileType(atPath: path)

        switch type {
        case .typeRegular:
            return .file(path, name)
        case .typeSymbolicLink:
            guard includeSymbolicLinks else { return nil }
            return .symbolLink(path, name)
        case .typeDirectory:
            let allContents = try fileManager
                .contentsOfDirectory(atPath: path)

            var contents = try allContents.prefix(maxLength)
                .compactMap { try nodeFrom(path: "\(path)/\($0)", depth: depth + 1) }
            if allContents.count > maxLength, !contents.isEmpty {
                let skippedFilesCount = allContents.count - maxLength
                contents.append(.file("", "\(skippedFilesCount) more file(s)"))
            }

            return .directory(path, name, contents)
        default:
            throw Error.invalidFileType
        }
    }

    /// Returns a type of file at the given path
    private func fileType(atPath path: String) throws -> FileAttributeType {
        let attr = try fileManager.attributesOfItem(atPath: path)
        let dict = NSDictionary(dictionary: attr)
        guard let type = dict.fileType() else {
            throw Error.invalidFileType
        }
        return FileAttributeType(rawValue: type)
    }

    /// Checks if a path is a symbolic link
    private func isSymbolicLink(atPath path: String) -> Bool {
        (try? fileManager.destinationOfSymbolicLink(atPath: path)) != nil
    }

    /// Checks if a path points to a directory. Uses fileExists which is faster than checking attributes, especially on iCloud folders.
    private func isDirectory(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
            return true
        }

        return false
    }
}
