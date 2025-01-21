/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
import AirshipPreferenceCenter
#endif

public class AirshipPreferenceCenterProxy {

    private let proxyStore: ProxyStore

    private let preferenceCenterProvider: () throws -> PreferenceCenter
    private var preferenceCenter: PreferenceCenter {
        get throws { try preferenceCenterProvider() }
    }

    init(
        proxyStore: ProxyStore,
        preferenceCenterProvider: @escaping () throws -> PreferenceCenter
    ) {
        self.proxyStore = proxyStore
        self.preferenceCenterProvider = preferenceCenterProvider
    }
    
    @MainActor
    public func displayPreferenceCenter(preferenceCenterID: String) throws {
        try self.preferenceCenter.open(preferenceCenterID)
    }

    public func setAutoLaunchPreferenceCenter(
        _ autoLaunch: Bool,
        preferenceCenterID: String
    ) {
        self.proxyStore.setAutoLaunchPreferenceCenter(
            preferenceCenterID,
            autoLaunch: autoLaunch
        )
    }

    public func getPreferenceCenterConfig(
        preferenceCenterID: String
    ) async throws -> [String: Any] {
        let config = try await self.preferenceCenter.jsonConfig(
            preferenceCenterID: preferenceCenterID
        )

        guard
            let converted = try JSONSerialization.jsonObject(with: config) as? [String: Any]
        else {
            throw AirshipErrors.error("Invalid preference config")
        }

        return converted
    }
}
