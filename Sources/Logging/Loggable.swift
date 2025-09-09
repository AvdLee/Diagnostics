import Foundation
import MetricKit

enum LoggableCSSClass: String, Sendable {
    case debug, error, system
}

protocol Loggable: Sendable {
    /// The date of the log event. If set, it will be prepended to the log message in the right format.
    var date: Date? { get }

    /// Any prefix to add before the actual message.
    var prefix: String? { get }

    /// The message to log.
    var message: String { get }

    /// An optional CSS class to add to the log. If set, the log will be surrounded with a `<p>` as well.
    var cssClass: LoggableCSSClass? { get }
}

extension Loggable {
    var date: Date? { nil }
    var prefix: String? { nil }
    var cssClass: LoggableCSSClass? { nil }

    var logData: Data {
        if let cssClass {
            Data("<p class=\"\(cssClass)\">\(logMessage)</p>\n".utf8)
        } else {
            Data("\(message)\n".utf8)
        }
    }

    private var logMessage: String {
        var messages: [String] = []
        if let date {
            let date = DateFormatter.current.string(from: date)
            messages.append("<span class=\"log-date\">\(date)</span>")
        }
        if let prefix {
            messages.append("<span class=\"log-prefix\">\(prefix)</span>")
        }
        messages.append("<span class=\"log-message\">\(self.message)</span>")
        return messages.joined(separator: "<span class=\"log-separator\"> | </span>")
    }
}

struct NewSession: Loggable {
    let message: String

    init() {
        let date = DateFormatter.current.string(from: Date())
        let appVersion = "\(Bundle.appVersion) (\(Bundle.appBuildNumber))"
        let system = "\(Device.systemName) \(Device.systemVersion)"
        let locale = Locale.preferredLanguages[0]

        /// We start with `\n\n---\n\n` for backwards compatibility since it's
        /// used for splitting the log into sections.
        var message = "\n\n---\n\n<summary><div class=\"session-header\">"
        message += "<p><span>Date: </span>\(date)</p>"
        message += "<p><span>System: </span>\(system)</p>"
        message += "<p><span>Locale: </span>\(locale)</p>"
        message += "<p><span>Version: </span>\(appVersion)</p>"
        message += "</div></summary>"
        self.message = message
    }
}

struct LogItem: Loggable {
    enum LogType {
        case debug(message: String)
        case error(error: Error, description: String?)

        var message: String {
            switch self {
            case .debug(let message):
                return message.addingHTMLEncoding()
            case .error(let error, let description):
                var message = "\(error) | \(error.localizedDescription)"

                if let description {
                    message += " | \(description)"
                }

                return "ERROR: \(message)".addingHTMLEncoding()
            }
        }

        var cssClass: LoggableCSSClass {
            switch self {
            case .debug:
                return .debug
            case .error:
                return .error
            }
        }
    }

    let date: Date? = Date()
    let prefix: String?
    let message: String
    let cssClass: LoggableCSSClass?

    init(_ type: LogType, file: String, function: String, line: UInt) {
        let file = String(describing: file).split(separator: "/").last.map(String.init) ?? String(describing: file)
        prefix = "\(file):L\(line)"
        self.message = type.message
        self.cssClass = type.cssClass
    }
}

struct SystemLog: Loggable {
    let date: Date? = Date()
    let message: String
    let cssClass: LoggableCSSClass? = .system

    init(line: String) {
        message = "SYSTEM: \(line)"
    }
}

struct ExceptionLog: Loggable {
    let message: String

    init(_ exception: NSException, description: String) {
        let message = """

        ---

        🚨 CRASH:
        Description: \(description)
        Exception name: \(exception.name.rawValue)
        Reason: \(exception.reason ?? "nil")

            \(Thread.callStackSymbols.joined(separator: "\n"))

        ---

        """

        self.message = message
    }
}

#if os(iOS)
extension MXDiagnosticPayload: @unchecked @retroactive Sendable {}
extension MXDiagnosticPayload: Loggable {
    var message: String {
        """

            ---
            MXDIAGNOSTICS RECEIVED:
            \(logDescription)
            ---

            """
    }
}

extension MXDiagnosticPayload {
    var logDescription: String {
        var logs: [String] = []
        logs.append(contentsOf: crashDiagnostics?.compactMap { $0.logDescription } ?? [])
        return logs.joined(separator: "\n")
    }
}

extension MXCrashDiagnostic {
    var logDescription: String {
        return """
        💥  Reason: \(terminationReason ?? "")
            Exception Type: \(exceptionType: exceptionType?.int32Value)
            Code: \(exceptionCode?.stringValue ?? "")
            Signal: \(signal: signal?.int32Value)
            OS: \(metaData.osVersion)
            Build: \(metaData.applicationBuildVersion)

        \(callStackTree.logDescription)
        """
    }
}

extension MXCallStackTree {
    var logDescription: String {
        let jsonData = jsonRepresentation()

        guard let object = try? JSONSerialization.jsonObject(with: jsonData, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]) else {
            return "Error: Call Stack Tree could not be parsed into a JSON string."
        }

        return String(decoding: data, as: UTF8.self)
    }
}

extension String.StringInterpolation {
    // swiftlint:disable:next cyclomatic_complexity
    mutating func appendInterpolation(exceptionType: Int32?) {
        guard let exceptionType else {
            appendLiteral("")
            return
        }

        let literal: String

        switch exceptionType {
        case EXC_BAD_ACCESS:
            literal = "EXC_BAD_ACCESS"
        case EXC_BAD_INSTRUCTION:
            literal = "EXC_BAD_INSTRUCTION"
        case EXC_ARITHMETIC:
            literal = "EXC_ARITHMETIC"
        case EXC_EMULATION:
            literal = "EXC_EMULATION"
        case EXC_SOFTWARE:
            literal = "EXC_SOFTWARE"
        case EXC_BREAKPOINT:
            literal = "EXC_BREAKPOINT"
        case EXC_SYSCALL:
            literal = "EXC_SYSCALL"
        case EXC_MACH_SYSCALL:
            literal = "EXC_MACH_SYSCALL"
        case EXC_RPC_ALERT:
            literal = "EXC_RPC_ALERT"
        case EXC_CRASH:
            literal = "EXC_CRASH"
        case EXC_RESOURCE:
            literal = "EXC_RESOURCE"
        case EXC_GUARD:
            literal = "EXC_GUARD"
        case EXC_CORPSE_NOTIFY:
            literal = "EXC_CORPSE_NOTIFY"

        default:
            literal = "\(exceptionType)"
        }

        appendLiteral(literal)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    mutating func appendInterpolation(signal: Int32?) {
        guard let signal else {
            appendLiteral("")
            return
        }

        let literal: String

        switch signal {
        case SIGHUP:
            literal = "SIGHUP"
        case SIGINT:
            literal = "SIGINT"
        case SIGQUIT:
            literal = "SIGQUIT"
        case SIGILL:
            literal = "SIGILL"
        case SIGTRAP:
            literal = "SIGTRAP"
        case SIGABRT:
            literal = "SIGABRT"
        case SIGIOT:
            literal = "SIGIOT"
        case SIGEMT:
            literal = "SIGEMT"
        case SIGFPE:
            literal = "SIGFPE"
        case SIGKILL:
            literal = "SIGKILL"
        case SIGBUS:
            literal = "SIGBUS"
        case SIGSEGV:
            literal = "SIGSEGV"
        case SIGSYS:
            literal = "SIGSYS"
        case SIGPIPE:
            literal = "SIGPIPE"
        case SIGALRM:
            literal = "SIGALRM"
        case SIGTERM:
            literal = "SIGTERM"
        case SIGURG:
            literal = "SIGURG"
        case SIGSTOP:
            literal = "SIGSTOP"
        case SIGTSTP:
            literal = "SIGTSTP"
        case SIGCONT:
            literal = "SIGCONT"
        case SIGCHLD:
            literal = "SIGCHLD"
        case SIGTTIN:
            literal = "SIGTTIN"
        case SIGTTOU:
            literal = "SIGTTOU"
        case SIGIO:
            literal = "SIGIO"
        case SIGXCPU:
            literal = "SICXCPU"
        case SIGXFSZ:
            literal = "SIGXFSZ"
        case SIGVTALRM:
            literal = "SIGVTALRM"
        case SIGPROF:
            literal = "SIGPROF"
        case SIGWINCH:
            literal = "SIGWINCH"
        case SIGINFO:
            literal = "SIGINFO"
        case SIGUSR1:
            literal = "SIGUSR1"
        case SIGUSR2:
            literal = "SIGUSR2"

        default:
            literal = "\(signal)"
        }

        self.appendLiteral(literal)
    }
}

#endif
