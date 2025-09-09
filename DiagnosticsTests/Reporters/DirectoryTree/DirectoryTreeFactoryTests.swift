//
//  DirectoryTreeFactoryTests.swift
//  
//
//  Created by Antoine van der Lee on 27/07/2022.
//

import XCTest
@testable import Diagnostics

final class DirectoryTreeFactoryTests: XCTestCase {

    func testPrettyStringForDocumentsTree() throws {
        let targetURL = try createTestDirectory()

        let directoryTree = try! DirectoryTreeFactory(
            path: targetURL.path,
            maxDepth: 10,
            maxLength: 10
        ).make()

        XCTAssertEqual(directoryTree.directories.count, 7)
        XCTAssertEqual(directoryTree.files.count, 14)
        XCTAssertEqual(directoryTree.prettyString(printFullPath: false).trimmingCharacters(in: .whitespacesAndNewlines),
        """
        └── treetest
            +-- Library
            |   +-- Preferences
            |   |   └── group.com.swiftlee.app.plist
            |   └── Caches
            |       └── com.apple.nsurlsessiond
            |           └── Downloads
            |               └── com.swiftlee
            +-- Coyote.sqlite
            └── thumbnails
                +-- 856F92AC-BB2E-4CDB-AC07-D911F98D7586.png
                +-- 7777DF69-03F4-4947-B545-3D5618FD6466.jpeg
                +-- DCCE00C8-4134-47F9-B7C3-53AB40FBF467.png
                +-- D6F1D540-502B-4574-A439-1746E08C2D26.png
                +-- 0A907756-CDD9-40F4-8BFD-CF6BF7FA6F02.png
                +-- 983B7B8F-7C65-467E-86B7-CC4813D7A348.png
                +-- 0FCC8A9D-C91E-49C8-B88B-FDD44501C120.png
                +-- 74134C19-32BD-43A5-8A73-236555022723.jpeg
                +-- 1FBF5079-120E-4E8A-8768-526CC9DB2B7A.png
                +-- BAD3B266-DA9B-4F28-8CD7-73880877450E.jpeg
                └── 3 more file(s)
        """)

    }

    func testPrettyStringMaxDepth() throws {
        let targetURL = try createTestDirectory()

        let directoryTree = try! DirectoryTreeFactory(
            path: targetURL.path,
            maxDepth: 1
        ).make()

        XCTAssertEqual(directoryTree.directories.count, 1)
        XCTAssertEqual(directoryTree.files.count, 0)
        XCTAssertEqual(directoryTree.prettyString(printFullPath: false).trimmingCharacters(in: .whitespacesAndNewlines), "└── treetest")
    }

    func testPrettyStringIncludingHiddenFiles() throws {
        let targetURL = try createTestDirectory()

        let directoryTree = try! DirectoryTreeFactory(
            path: targetURL.path,
            maxDepth: 2,
            includeHiddenFiles: true
        ).make()

        XCTAssertEqual(directoryTree.directories.count, 3)
        XCTAssertEqual(directoryTree.files.count, 2)
        XCTAssertEqual(directoryTree.prettyString(printFullPath: false).trimmingCharacters(in: .whitespacesAndNewlines),
        """
        └── treetest
            +-- Library
            +-- Coyote.sqlite
            +-- .git
            └── thumbnails
        """)
    }

    func createTestDirectory() throws -> URL {
        let documentsURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask).first!
        let baseURL = documentsURL.appendingPathComponent("treetest")
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)

        addTeardownBlock {
            try? FileManager.default.removeItem(at: baseURL)
        }

        let nodes: [DirectoryTreeNode] = [
            .file("", "Coyote.sqlite"),
            .file("", ".git"),
            .directory("", "thumbnails", [
                .file("", "856F92AC-BB2E-4CDB-AC07-D911F98D7586.png"),
                .file("", "7777DF69-03F4-4947-B545-3D5618FD6466.jpeg"),
                .file("", "DCCE00C8-4134-47F9-B7C3-53AB40FBF467.png"),
                .file("", "D6F1D540-502B-4574-A439-1746E08C2D26.png"),
                .file("", "0A907756-CDD9-40F4-8BFD-CF6BF7FA6F02.png"),
                .file("", "983B7B8F-7C65-467E-86B7-CC4813D7A348.png"),
                .file("", "0FCC8A9D-C91E-49C8-B88B-FDD44501C120.png"),
                .file("", "74134C19-32BD-43A5-8A73-236555022723.jpeg"),
                .file("", "1FBF5079-120E-4E8A-8768-526CC9DB2B7A.png"),
                .file("", "BAD3B266-DA9B-4F28-8CD7-73880877450E.jpeg"),
                .file("", "8783969E-5190-4041-8AD8-AF9E60ACFCD2.png"),
                .file("", "643D317B-C9A4-4528-87F5-4EA57045D82B.jpeg"),
                .file("", "73C3984D-A400-4C34-8451-1875323808B9.png")
            ]),
            .directory("", "Library", [
                .directory("", "Preferences", [
                    .file("", "group.com.swiftlee.app.plist")
                ]),
                .directory("", "Caches", [
                    .directory("", "com.apple.nsurlsessiond", [
                        .directory("", "Downloads", [
                            .file("", "com.swiftlee")
                        ])
                    ])
                ])
            ])
        ]

        for node in nodes {
            try createNode(node, at: baseURL)
        }

        return baseURL
    }

    func createNode(_ node: DirectoryTreeNode, at baseURL: URL) throws {
        switch node {
        case .file(_, let name):
            let newBaseURL = baseURL.appendingPathComponent(name)
            FileManager.default.createFile(atPath: newBaseURL.path, contents: Data())
        case .symbolLink:
            fatalError("Symbol links are not supported for now")
        case .directory(_, let name, let childNodes):
            let newBaseURL = baseURL.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: newBaseURL, withIntermediateDirectories: true, attributes: nil)
            try childNodes.forEach { childNode in
                try createNode(childNode, at: newBaseURL)
            }
        }
    }

}
