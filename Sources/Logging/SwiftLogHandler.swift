//
//  SwiftLogHandler.swift
//  Diagnostics
//

import Foundation
import Logging

extension DiagnosticsLogger {

    /// A SwiftLog `LogHandler` that forwards log messages to a `DiagnosticsLogger` instance.
    ///
    /// Usage:
    /// ```swift
    /// import Logging
    ///
    /// try DiagnosticsLogger.setup()
    /// LoggingSystem.bootstrap { label in
    ///     DiagnosticsLogger.SwiftLogHandler(label: label)
    /// }
    ///
    /// let logger = Logger(label: "com.example.app")
    /// logger.info("Hello from SwiftLog!")
    /// ```
    ///
    /// ## Log Level Mapping
    ///
    /// | SwiftLog Level | Diagnostics Level |
    /// |----------------|-------------------|
    /// | trace          | debug             |
    /// | debug          | debug             |
    /// | info           | debug             |
    /// | notice         | debug             |
    /// | warning        | debug             |
    /// | error          | error             |
    /// | critical       | error             |
    public struct SwiftLogHandler: LogHandler, @unchecked Sendable {
        public let label: String
        private let logger: DiagnosticsLogger

        public var logLevel: Logger.Level
        public var metadata: Logger.Metadata

        public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
            get { metadata[key] }
            set { metadata[key] = newValue }
        }

        /// Creates a new SwiftLog handler backed by the given `DiagnosticsLogger`.
        /// - Parameters:
        ///   - label: The logger label provided by SwiftLog's `LoggingSystem.bootstrap`.
        ///   - logger: The `DiagnosticsLogger` instance to write to. Defaults to `.standard`.
        ///   - logLevel: The minimum log level to forward. Defaults to `.debug`.
        ///   - metadata: Initial metadata. Defaults to empty.
        public init(
            label: String,
            logger: DiagnosticsLogger = .standard,
            logLevel: Logger.Level = .debug,
            metadata: Logger.Metadata = [:]
        ) {
            self.label = label
            self.logger = logger
            self.logLevel = logLevel
            self.metadata = metadata
        }

        public func log(
            level: Logger.Level,
            message: Logger.Message,
            metadata: Logger.Metadata?,
            source: String,
            file: String,
            function: String,
            line: UInt
        ) {
            let mergedMetadata = self.metadata.merging(metadata ?? [:]) { _, new in new }

            var fullMessage = message.description
            if !mergedMetadata.isEmpty {
                let metadataString = mergedMetadata
                    .sorted(by: { $0.key < $1.key })
                    .map { "\($0.key): \($0.value)" }
                    .joined(separator: ", ")
                fullMessage = "[\(metadataString)] \(fullMessage)"
            }

            if !label.isEmpty {
                fullMessage = "[\(label)] \(fullMessage)"
            }

            switch level {
            case .trace, .debug, .info, .notice, .warning:
                logger.log(
                    LogItem(.debug(message: fullMessage), file: file, function: function, line: line)
                )
            case .error, .critical:
                let error = DiagnosticsSwiftLogError(message: fullMessage, level: level)
                logger.log(
                    LogItem(.error(error: error, description: nil), file: file, function: function, line: line)
                )
            }
        }
    }
}

/// A lightweight error type used to carry SwiftLog error/critical messages
/// through the `LogItem.LogType.error` case.
private struct DiagnosticsSwiftLogError: Error, CustomStringConvertible, Sendable {
    let message: String
    let level: String

    init(message: String, level: Logger.Level) {
        self.message = message
        self.level = "\(level)"
    }

    var description: String {
        "[\(level)] \(message)"
    }
}