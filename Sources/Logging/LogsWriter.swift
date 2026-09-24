//
//  LogsWriter.swift
//  Diagnostics
//
//  Created by A.J. van der Lee on 01/07/2025.
//

import Foundation
import os.log

protocol LogsWriting: Sendable {
    @discardableResult
    func write(_ loggables: [any Loggable]) -> LogsWriter.WriteOutcome
}

struct LogsWriter: LogsWriting {
    enum WriteOutcome: Equatable {
        case appended
        case trimmed
        case failed
    }

    let logFileLocation: URL
    let maximumLogSize: Int

    /// The size the log is trimmed down to once it exceeds `maximumLogSize`.
    /// Leaving headroom below the maximum prevents trimming on every subsequent write.
    var trimTargetSize: Int {
        maximumLogSize / 4 * 3
    }

    @discardableResult
    func write(_ loggable: any Loggable) -> WriteOutcome {
        write([loggable])
    }

    @discardableResult
    func write(_ loggables: [any Loggable]) -> WriteOutcome {
        let data = loggables.reduce(into: Data()) { data, loggable in
            data.append(loggable.logData)
        }
        guard !data.isEmpty else { return .appended }

        let totalFileSize: UInt64
        do {
            totalFileSize = try append(data)
        } catch {
            Self.report(error, during: "appending log data")
            return .failed
        }

        do {
            return try trimIfNecessary(logSize: totalFileSize) ? .trimmed : .appended
        } catch {
            Self.report(error, during: "trimming the log file at \(logFileLocation.path)")
            return .appended
        }
    }

    /// Appends the data and returns the resulting total file size.
    /// The file handle is closed before returning so trimming can safely
    /// replace the file without an open handle on the same path.
    private func append(_ data: Data) throws -> UInt64 {
        let fileHandle = try FileHandle(forWritingTo: logFileLocation)
        defer {
            try? fileHandle.close()
        }
        try fileHandle.seekToEnd()
        try fileHandle.write(contentsOf: data)
        return try fileHandle.offset()
    }

    private func trimIfNecessary(logSize: UInt64) throws -> Bool {
        guard logSize > maximumLogSize else { return false }

        let data = try Data(contentsOf: logFileLocation, options: .mappedIfSafe)
        guard let trimmedData = LogsTrimmer.trim(data, toTargetSize: trimTargetSize) else { return false }

        try trimmedData.write(to: logFileLocation, options: .atomic)
        return true
    }

    /// Reports a failure without terminating the app and without using `print`:
    /// stdout/stderr are piped back into the diagnostics logger, which could
    /// recursively trigger the same failing write.
    private static func report(_ error: Error, during operation: String) {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain, nsError.code == NSFileWriteOutOfSpaceError {
            os_log(.error, "Diagnostics failed %{public}@: the device is out of storage space. %{public}@", operation, nsError.description)
        } else {
            os_log(.error, "Diagnostics failed %{public}@: %{public}@", operation, nsError.description)
        }
    }
}
