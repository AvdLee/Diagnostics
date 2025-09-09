//
//  UpdateAvailableInsight.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 09/02/2022.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import Foundation

/// Uses the bundle identifier to fetch latest version information and provides insights into whether
/// an app update is available.
struct UpdateAvailableInsight: SmartInsightProviding {

    let name = "Update available"
    let bundleIdentifier: String
    let currentVersion: String
    let itunesRegion: String
    let appMetadataCompletion: (() -> Result<AppMetadataResults, Error>)?

    init?(
        bundleIdentifier: String? = Bundle.main.bundleIdentifier,
        currentVersion: String = Bundle.appVersion,
        itunesRegion: String = Locale.current.region?.identifier ?? "us",
        appMetadataCompletion: (() -> Result<AppMetadataResults, Error>)? = nil
    ) {
        guard let bundleIdentifier else { return nil }
        
        self.bundleIdentifier = bundleIdentifier
        self.currentVersion = currentVersion
        self.itunesRegion = itunesRegion
        self.appMetadataCompletion = appMetadataCompletion
    }
    
    func generateResult() async -> InsightResult? {
        let url = URL(string: "https://itunes.apple.com/\(itunesRegion)/lookup?bundleId=\(bundleIdentifier)")!

        var appMetadata: AppMetadata?
        if let appMetadataCompletion {
            switch appMetadataCompletion() {
            case .success(let result):
                appMetadata = result.results.first
            case .failure:
                return nil
            }
        } else {
            guard let (data, _) = try? await URLSession.shared.data(from: url), let result = try? JSONDecoder().decode(AppMetadataResults.self, from: data) else {
                return nil
            }
            appMetadata = result.results.first
        }

        guard let appMetadata else {
            return nil
        }

        switch currentVersion.compare(appMetadata.version) {
        case .orderedSame:
            return .success(message: "The user is using the latest app version \(appMetadata.version)")
        case .orderedDescending:
            return .success(message: "The user is using a newer version \(currentVersion)")
        case .orderedAscending:
            return .warn(message: "The user could update to \(appMetadata.version)")
        }
    }
}

struct AppMetadataResults: Codable {
    let results: [AppMetadata]
}

// A list of App metadata with details around a given app.
struct AppMetadata: Codable {
    /// The current latest version available in the App Store.
    let version: String
}
