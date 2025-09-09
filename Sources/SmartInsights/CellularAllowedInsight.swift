//
//  CellularAllowedInsight.swift
//
//
//  Created by Antoine van der Lee on 27/07/2022.
//

#if canImport(CoreTelephony)
    import CoreTelephony
#endif
import Foundation

#if os(iOS) && !targetEnvironment(macCatalyst)
/// Shows an insight on whether the user has enabled cellular data system-wide for this app.
struct CellularAllowedInsight: SmartInsightProviding {

    let name = "Cellular data allowed"

    func generateResult() async -> InsightResult? {
        let cellularData = CTCellularData()
        switch cellularData.restrictedState {
        case .restricted:
            return .error(message: "The user has disabled cellular data usage for this app.")
        case .notRestricted:
            return .success(message: "Cellular data is enabled for this app.")
        default:
            return .warn(message: "Unable to determine whether cellular data is allowed for this app.")
        }
    }
}
#endif
