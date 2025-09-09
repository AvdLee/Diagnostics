//
//  DiagnosticsLogger.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import ExceptionCatcher
import Foundation
import MetricKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// A Diagnostics Logger to log messages to which will end up in the Diagnostics Report if using the default `LogsReporter`.
/// Will keep a `.txt` log in the documents directory with the latestlogs with a max size of 2 MB.
public final class DiagnosticsLogger: Sendable {
    static let standard = DiagnosticsLogger()

    private static let logFileLocation: URL = FileManager.default.documentsDirectory.appendingPathComponent("diagnostics_log.txt")

    private let inputPipe = Pipe()
    private let outputPipe = Pipe()

    private let queue = DispatchQueue(
        label: "com.wetransfer.diagnostics.logger",
        qos: .utility,
        autoreleaseFrequency: .workItem,
        target: .global(qos: .utility)
    )

    private let logsWriter = LogsWriter(
        logFileLocation: DiagnosticsLogger.logFileLocation,
        maximumLogSize: 2 * 1024 * 1024 // 2 MB
    )
    private var isRunningTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
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
        guard !isSetUp() || standard.isRunningTests else {
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
                .createDirectory(atPath: FileManager.default.documentsDirectory.path, withIntermediateDirectories: true, attributes: nil)
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
        guard isSetup else {
            return assertionFailure("Trying to log a message while not set up")
        }

        queue.async { [weak self] in
            self?.logsWriter.write(loggable)
        }
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
        dup2(STDOUT_FILENO, outputPipe.fileHandleForWriting.fileDescriptor)

        // Send all output (STDOUT and STDERR) to our `Pipe`.
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
    }

    private func handleLoggedData(_ data: Data) {
        do {
            try ExceptionCatcher.catch { () -> Void in
                outputPipe.fileHandleForWriting.write(data)

                let string = String(decoding: data, as: UTF8.self)
                string.enumerateLines(invoking: { [weak self] line, _ in
                    self?.log(SystemLog(line: line))
                })
            }
        } catch {
            print("Exception was catched \(error)")
        }
    }
}

private extension FileManager {
    var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func fileExistsAndIsFile(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        if fileExists(atPath: path, isDirectory: &isDirectory) {
            return !isDirectory.boolValue
        } else {
            return false
        }
    }
}
