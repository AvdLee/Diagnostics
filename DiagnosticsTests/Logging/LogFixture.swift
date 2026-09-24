//
//  LogFixture.swift
//  DiagnosticsTests
//

@testable import Diagnostics
import Foundation

/// Builds log files shaped like long-running production logs: legacy HTML sessions from before
/// structured logging, many blank lines, and structured records including empty system records.
struct LogFixture {
    let data: Data

    /// The structured records worth keeping, in file order, without their trailing newline.
    let meaningfulLines: [String]

    static func productionShaped(minimumSize: Int) -> LogFixture {
        var data = Data()
        var meaningfulLines: [String] = []

        let legacySession = """
        <summary><div class="session-header"><p><span>Date: </span>2025-03-01 09:12:44</p><p><span>System: </span>macOS 15.3</p></div></summary>
        <p class="system"><span class="log-date">2025-03-01 09:12:44</span><span class="log-separator"> | </span><span class="log-message">SYSTEM: Legacy launch</span></p>
        <p class="debug"><span class="log-date">2025-03-01 09:12:45</span><span class="log-separator"> | </span><span class="log-message">Legacy multi-line message
        continuation text of the legacy message</span></p>


        """
        while data.count < minimumSize / 10 {
            data.append(Data(legacySession.utf8))
        }

        let blankLines = Data(String(repeating: "\n", count: 20).utf8)
        var recordIndex = 0
        while data.count <= minimumSize {
            let session = NewSession().logData
            data.append(session)
            meaningfulLines.append(line(from: session))

            for _ in 0..<50 {
                let record = SystemLog(line: String(format: "Fixture record %06d", recordIndex)).logData
                recordIndex += 1
                data.append(record)
                meaningfulLines.append(line(from: record))

                if recordIndex.isMultiple(of: 3) {
                    data.append(SystemLog(line: "").logData)
                }
                data.append(blankLines)
            }
        }

        return LogFixture(data: data, meaningfulLines: meaningfulLines)
    }

    static func line(from logData: Data) -> String {
        String(decoding: logData, as: UTF8.self).trimmingCharacters(in: .newlines)
    }

    static func lines(in data: Data) -> [String] {
        String(decoding: data, as: UTF8.self)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .filter { !$0.isEmpty }
    }
}
