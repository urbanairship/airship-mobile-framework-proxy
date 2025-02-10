/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
public import AirshipKit
#elseif canImport(AirshipCore)
public import AirshipCore
import AirshipPreferenceCenter
#endif

public final class AirshipPreferenceCenterProxy: Sendable {

    private let proxyStore: ProxyStore

    private let preferenceCenterProvider: @Sendable () throws -> PreferenceCenter
    private var preferenceCenter: PreferenceCenter {
        get throws { try preferenceCenterProvider() }
    }

    init(
        proxyStore: ProxyStore,
        preferenceCenterProvider: @Sendable @escaping () throws -> PreferenceCenter
    ) {
        self.proxyStore = proxyStore
        self.preferenceCenterProvider = preferenceCenterProvider
    }
    
    @MainActor
    public func displayPreferenceCenter(preferenceCenterID: String) throws {
        try self.preferenceCenter.open(preferenceCenterID)
    }

    @MainActor
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
    ) async throws -> AirshipJSON {
        let config = try await self.preferenceCenter.jsonConfig(
            preferenceCenterID: preferenceCenterID
        )

        return try AirshipJSON.from(data: config)
    }
}
