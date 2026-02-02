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

    private let preferenceCenterProvider: @Sendable @MainActor () throws -> any PreferenceCenter

    @MainActor
    private var preferenceCenter: any PreferenceCenter {
        get throws { try preferenceCenterProvider() }
    }

    init(
        proxyStore: ProxyStore,
        preferenceCenterProvider: @Sendable @MainActor @escaping () throws -> any PreferenceCenter
    ) {
        self.proxyStore = proxyStore
        self.preferenceCenterProvider = preferenceCenterProvider
    }
    
    @MainActor
    public func displayPreferenceCenter(preferenceCenterID: String) throws {
        AirshipLogger.trace("displayPreferenceCenter called, preferenceCenterID=\(preferenceCenterID)")
        try self.preferenceCenter.display(preferenceCenterID)
    }

    @MainActor
    public func setAutoLaunchPreferenceCenter(
        _ autoLaunch: Bool,
        preferenceCenterID: String
    ) {
        AirshipLogger.trace("setAutoLaunchPreferenceCenter called, preferenceCenterID=\(preferenceCenterID), autoLaunch=\(autoLaunch)")
        self.proxyStore.setAutoLaunchPreferenceCenter(
            preferenceCenterID,
            autoLaunch: autoLaunch
        )
    }

    public func getPreferenceCenterConfig(
        preferenceCenterID: String
    ) async throws -> AirshipJSON {
        AirshipLogger.trace("getPreferenceCenterConfig called, preferenceCenterID=\(preferenceCenterID)")
        let config = try await self.preferenceCenter.jsonConfig(
            preferenceCenterID: preferenceCenterID
        )

        return try AirshipJSON.from(data: config)
    }
}
