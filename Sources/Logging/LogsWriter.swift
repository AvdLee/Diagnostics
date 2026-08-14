//
//  LogsWriter.swift
//  Diagnostics
//
//  Created by A.J. van der Lee on 01/07/2025.
//

import Foundation
import os.log

struct LogsWriter {
    let logFileLocation: URL
    let maximumLogSize: Int

    private static let numberOfRecordsToTrimPerBatch = 10

    func write(_ loggable: Loggable) {
        let totalFileSize: UInt64
        do {
            totalFileSize = try append(loggable.logData)
        } catch {
            Self.report(error, during: "appending log data")
            return
        }

        do {
            try trimIfNecessary(logSize: totalFileSize)
        } catch {
            Self.report(error, during: "trimming the log file at \(logFileLocation.path)")
        }
    }

    /// Appends the record and returns the resulting total file size.
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

    private func trimIfNecessary(logSize: UInt64) throws {
        guard logSize > maximumLogSize else { return }

        var data = try Data(contentsOf: logFileLocation, options: .mappedIfSafe)
        guard !data.isEmpty else { return }

        let trimmer = LogsTrimmer(numberOfLinesToTrim: Self.numberOfRecordsToTrimPerBatch)
        var didTrim = false
        while data.count > maximumLogSize {
            let sizeBeforeTrim = data.count
            trimmer.trim(data: &data)

            /// Stop once no trimmable records remain to prevent an infinite loop,
            /// e.g. when the remaining content consists of untrimmable session headers.
            guard data.count < sizeBeforeTrim else { break }
            didTrim = true
        }

        guard didTrim else { return }
        try data.write(to: logFileLocation, options: .atomic)
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
