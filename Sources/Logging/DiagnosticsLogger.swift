//
//  DiagnosticsLogger.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import ExceptionCatcher
import Foundation
import MetricKit

#if os(macOS)
import Security
#endif

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// A Diagnostics Logger to log messages to which will end up in the Diagnostics Report if using the default `LogsReporter`.
/// Will keep a `.txt` log in the Application Support directory with the latest logs with a max size of 3 MB.
public final class DiagnosticsLogger: Sendable {
    static let standard = DiagnosticsLogger()

    static let maximumLogSize = 3 * 1024 * 1024 // 3 MB

    private static let logFileLocation: URL = FileManager.default.applicationSupportDirectory.appendingPathComponent("diagnostics_log.txt")

    private let inputPipe = Pipe()
    private let standardOutputReplay: StandardOutputReplay

    private let queue = DispatchQueue(
        label: "com.swiftlee.diagnostics.logger",
        qos: .utility,
        autoreleaseFrequency: .workItem,
        target: .global(qos: .utility)
    )

    private let logsWriter: any LogsWriting

    init(
        logsWriter: any LogsWriting = LogsWriter(
            logFileLocation: DiagnosticsLogger.logFileLocation,
            maximumLogSize: DiagnosticsLogger.maximumLogSize
        ),
        standardOutputReplay: StandardOutputReplay = StandardOutputReplay()
    ) {
        self.logsWriter = logsWriter
        self.standardOutputReplay = standardOutputReplay
    }

    private var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestBundlePath"] != nil
            || ProcessInfo.processInfo.arguments.contains { argument in
                argument.hasSuffix(".xctest") || argument.contains(".xctest/")
            }
            || NSClassFromString("XCTest.XCTestCase") != nil
            || NSClassFromString("XCTestCase") != nil
    }

    private let metricsMonitor = MetricsMonitor()

    /// Whether the logger is setup and ready to use.
    private var isSetup: Bool {
        inputPipe.fileHandleForReading.readabilityHandler != nil || isRunningTests
    }

    /// Whether the logger is setup and ready to use.
    public static func isSetUp() -> Bool {
        return standard.isSetup
    }

    /// Sets up the logger to be ready for usage. This needs to be called before any log messages are reported.
    /// This method also starts a new session.
    public static func setup() throws {
        guard
            !isSetUp() || standard.isRunningTests || !FileManager.default.fileExists(atPath: logFileLocation.path)
        else {
            return
        }
        try standard.setup()
    }

    /// Logs the given message for the diagnostics report.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: The file from which the log is send. Defaults to `#file`.
    ///   - function: The functino from which the log is send. Defaults to `#function`.
    ///   - line: The line from which the log is send. Defaults to `#line`.
    public static func log(message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        standard.log(LogItem(.debug(message: message), file: file, function: function, line: line))
    }

    /// Logs the given error for the diagnostics report.
    /// - Parameters:
    ///   - error: The error to log.
    ///   - description: An optional description parameter to add extra info about the error.
    ///   - file: The file from which the log is send. Defaults to `#file`.
    ///   - function: The functino from which the log is send. Defaults to `#function`.
    ///   - line: The line from which the log is send. Defaults to `#line`.
    public static func log(
        error: Error,
        description: String? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        standard.log(LogItem(.error(error: error, description: description), file: file, function: function, line: line))
    }
}

// MARK: - Setup
extension DiagnosticsLogger {

    private func setup() throws {
        if !FileManager.default.fileExists(atPath: DiagnosticsLogger.logFileLocation.path) {
            try FileManager.default
                .createDirectory(atPath: FileManager.default.applicationSupportDirectory.path, withIntermediateDirectories: true, attributes: nil)
            guard FileManager.default.createFile(atPath: DiagnosticsLogger.logFileLocation.path, contents: nil, attributes: nil) else {
                assertionFailure("Unable to create the log file")
                return
            }
        }

        setupPipe()
        metricsMonitor.startMonitoring()
        startNewSession()
    }
}

// MARK: - Setup & Logging
extension DiagnosticsLogger {

    /// Creates a new section in the overall logs with data about the session start and system information.
    func startNewSession() {
        log(NewSession())
    }

    /// Reads the log and converts it to a `Data` object.
    func readLog() throws -> Data? {
        guard isSetup else {
            assertionFailure("Trying to read the log while not set up")
            return nil
        }

        return try queue.sync {
            let coordinator = NSFileCoordinator(filePresenter: nil)
            var coordinateError: NSError?
            var dataError: Error?
            var logData: Data?
            coordinator.coordinate(readingItemAt: DiagnosticsLogger.logFileLocation, error: &coordinateError) { url in
                do {
                    logData = try Data(contentsOf: url)
                } catch {
                    dataError = error
                }
            }

            if let coordinateError {
                throw coordinateError
            } else if let dataError {
                throw dataError
            }

            return logData
        }
    }

    /// Removes the log file. Should only be used for testing purposes.
    func deleteLogs() throws {
        queue.sync {
            guard FileManager.default.fileExists(atPath: DiagnosticsLogger.logFileLocation.path) else { return }
            try? FileManager.default.removeItem(atPath: DiagnosticsLogger.logFileLocation.path)
        }
    }

    func log(_ loggable: Loggable) {
        log([loggable])
    }

    /// Writes all given records with a single append.
    func log(_ loggables: [any Loggable]) {
        guard isSetup else {
            return assertionFailure("Trying to log a message while not set up")
        }

        queue.async { [weak self] in
            self?.logsWriter.write(loggables)
        }
    }

    func logSynchronously(_ loggable: Loggable) {
        guard isSetup else {
            return assertionFailure("Trying to log a message while not set up")
        }

        queue.sync { [weak self] in
            _ = self?.logsWriter.write([loggable])
        }
    }

    /// Blocks until all previously scheduled writes have finished.
    func waitForPendingWrites() {
        queue.sync {}
    }
}

// MARK: - System logs
extension DiagnosticsLogger {

    private func setupPipe() {
        guard !isRunningTests else { return }

        inputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            self?.handleLoggedData(data)
        }

        // Copy the STDOUT file descriptor into our output pipe's file descriptor
        // So we can write the strings back to STDOUT and it shows up again in the Xcode console.
        dup2(STDOUT_FILENO, standardOutputReplay.fileDescriptor)

        // Send all output (STDOUT and STDERR) to our `Pipe`.
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
    }

    func handleLoggedData(_ data: Data) {
        standardOutputReplay.write(data)

        let systemLogs = Self.systemLogs(from: data)
        guard !systemLogs.isEmpty else { return }
        log(systemLogs)
    }

    /// Converts captured stdout/stderr output into system logs, skipping empty and whitespace-only lines.
    static func systemLogs(from data: Data) -> [SystemLog] {
        var systemLogs: [SystemLog] = []
        String(decoding: data, as: UTF8.self).enumerateLines { line, _ in
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            systemLogs.append(SystemLog(line: line))
        }
        return systemLogs
    }
}

final class StandardOutputReplay: @unchecked Sendable {
    private let fileHandle: FileHandle
    private let lock = NSLock()
    private var enabled = true

    init(fileHandle: FileHandle = Pipe().fileHandleForWriting) {
        self.fileHandle = fileHandle
    }

    var fileDescriptor: Int32 {
        fileHandle.fileDescriptor
    }

    var isEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return enabled
    }

    func write(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }

        guard enabled else { return }

        do {
            try ExceptionCatcher.catch {
                fileHandle.write(data)
            }
        } catch {
            // stdout and stderr are redirected into the diagnostics input pipe.
            // Reporting this failure through either stream would recursively
            // invoke this method, so disable replay silently.
            enabled = false
        }
    }
}

extension FileManager {
    /// Location of the logger's Application Support directory.
    ///
    /// On sandboxed processes (iOS, tvOS, watchOS, and sandboxed macOS apps) the system already
    /// scopes `~/Library/Application Support/` to a per-app container, so the base URL is returned
    /// unchanged. On unsandboxed macOS apps the base URL is shared across every app on the
    /// machine, which would cause `diagnostics_log.txt` to collide between apps. In that case we
    /// append the main bundle's identifier as a subdirectory to keep the log app-scoped.
    var applicationSupportDirectory: URL {
        let baseURL = urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        #if os(macOS)
        guard !Self.isSandboxed, let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return baseURL
        }
        return baseURL.appendingPathComponent(bundleIdentifier)
        #else
        return baseURL
        #endif
    }

    #if os(macOS)
    /// Whether the current process has the `com.apple.security.app-sandbox` entitlement active.
    /// Uses the Security framework's task-entitlement API rather than environment sniffing so the
    /// check reflects the code signature rather than the inherited environment.
    static var isSandboxed: Bool {
        guard let task = SecTaskCreateFromSelf(nil) else { return false }
        let value = SecTaskCopyValueForEntitlement(task, "com.apple.security.app-sandbox" as CFString, nil)
        return (value as? Bool) ?? false
    }
    #endif

    func fileExistsAndIsFile(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        if fileExists(atPath: path, isDirectory: &isDirectory) {
            return !isDirectory.boolValue
        } else {
            return false
        }
    }
}
