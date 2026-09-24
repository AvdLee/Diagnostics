//
//  DiagnosticsLoggerStandardOutputTests.swift
//  DiagnosticsTests
//

@testable import Diagnostics
import Foundation
import Testing

@Suite("DiagnosticsLogger standard output capture")
struct DiagnosticsLoggerStandardOutputTests {

    private final class RecordingLogsWriter: LogsWriting, @unchecked Sendable {
        private let lock = NSLock()
        private var recordedWrites: [[any Loggable]] = []

        var writes: [[any Loggable]] {
            lock.withLock { recordedWrites }
        }

        func write(_ loggables: [any Loggable]) -> LogsWriter.WriteOutcome {
            lock.withLock { recordedWrites.append(loggables) }
            return .appended
        }
    }

    /// Kept alive for the lifetime of the test so replayed output has an open reader instead of raising `SIGPIPE`.
    private let replayPipe = Pipe()

    private func makeLogger(writer: RecordingLogsWriter) -> DiagnosticsLogger {
        DiagnosticsLogger(
            logsWriter: writer,
            standardOutputReplay: StandardOutputReplay(fileHandle: replayPipe.fileHandleForWriting)
        )
    }

    @Test("Empty and whitespace-only lines produce no system logs")
    func skipsEmptyLines() {
        #expect(DiagnosticsLogger.systemLogs(from: Data("\n\n   \n\t\n".utf8)).isEmpty)
    }

    @Test("A multi-line chunk becomes a single write without empty lines")
    func writesChunkOnce() {
        let writer = RecordingLogsWriter()
        let logger = makeLogger(writer: writer)

        logger.handleLoggedData(Data("first\n\nsecond\n  \nthird\n".utf8))
        logger.waitForPendingWrites()

        let writes = writer.writes
        #expect(writes.count == 1)
        #expect(writes.first?.map(\.message) == ["SYSTEM: first", "SYSTEM: second", "SYSTEM: third"])
    }

    @Test("A chunk with only empty lines does not write")
    func skipsEmptyChunk() {
        let writer = RecordingLogsWriter()
        let logger = makeLogger(writer: writer)

        logger.handleLoggedData(Data("\n \n\n".utf8))
        logger.waitForPendingWrites()

        #expect(writer.writes.isEmpty)
    }
}
