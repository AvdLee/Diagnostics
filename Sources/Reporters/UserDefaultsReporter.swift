//
//  UserDefaultsReporter.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import Foundation

/// User Defaults is thread-safe, so it's fine to mark this retroactively as `Sendable`.
extension UserDefaults: @unchecked @retroactive Sendable { }

/// Generates a report from all the registered UserDefault keys.
public final class UserDefaultsReporter: DiagnosticsReporting {

    private let userDefaults: UserDefaults

    /// All the keys that should be read from the given `UserDefaults` instance.
    public let keys: [String]

    public init(userDefaults: UserDefaults, keys: [String]) {
        self.userDefaults = userDefaults
        self.keys = keys
    }

    public func report() -> DiagnosticsChapter {
        let userDefaultsDiagnostics = keys.reduce(into: [:]) { dictionary, key in
            dictionary[key] = "\(String(describing: userDefaults.object(forKey: key)))"
        }

        return DiagnosticsChapter(title: "UserDefaults", diagnostics: userDefaultsDiagnostics, formatter: Self.self)
    }
}

extension UserDefaultsReporter: HTMLFormatting {
    public static func format(_ diagnostics: Diagnostics) -> HTML {
        guard let userDefaultsDict = diagnostics as? [String: Any] else { return diagnostics.html() }
        return "<pre>\(userDefaultsDict.jsonRepresentation ?? "Could not parse User Defaults")</pre>"
    }
}

private extension Dictionary where Key == String, Value == Any {
    var jsonRepresentation: String? {
        let options: JSONSerialization.WritingOptions
        if #available(iOS 11.0, *) {
            options = [.prettyPrinted, .sortedKeys, .fragmentsAllowed]
        } else {
            options = [.prettyPrinted, .fragmentsAllowed]
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonCompatible, options: options) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }

    var jsonCompatible: [String: Any] {
        return mapValues { value -> Any in
            if let dict = value as? [String: Any] {
                return dict.jsonCompatible
            } else if let array = value as? [Any] {
                return array.map { "\($0)" }
            }

            return "\(value)"
        }
    }
}
