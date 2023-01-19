/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

@objc
public class AirshipPreferenceCenterProxy: NSObject {

    private let proxyStore: ProxyStore

    private let preferenceCenterProvider: () throws -> AirshipPreferenceCenterProtocol
    private var preferenceCenter: AirshipPreferenceCenterProtocol {
        get throws { try preferenceCenterProvider() }
    }

    init(
        proxyStore: ProxyStore,
        preferenceCenterProvider: @escaping () throws -> AirshipPreferenceCenterProtocol
    ) {
        self.proxyStore = proxyStore
        self.preferenceCenterProvider = preferenceCenterProvider
    }

    @objc
    public func displayPreferenceCenter(preferenceCenterId: String) throws {
        try self.preferenceCenter.open(preferenceCenterId)
    }

    @objc
    public func setAutoLaunchPreferenceCenter(
        _ autoLaunch: Bool,
        forPreferenceId preferenceId: String
    ) {
        self.proxyStore.setAutoLaunchPreferenceCenter(
            preferenceId,
            autoLaunch: autoLaunch
        )
    }

    @objc
    public func getPreferenceCenterConfig(
        preferenceCenterID: String
    ) async throws -> [String: Any] {
        return try await self.preferenceCenter.getPreferenceCenterConfig(
            preferenceCenterID: preferenceCenterID
        )
    }
}

protocol AirshipPreferenceCenterProtocol: AnyObject {
    func open(_ preferenceCenterID: String)
    func getPreferenceCenterConfig(
        preferenceCenterID: String
    ) async -> [String: Any]
}

extension PreferenceCenter : AirshipPreferenceCenterProtocol {
    func getPreferenceCenterConfig(
        preferenceCenterID: String
    ) async -> [String : Any] {
        return await withCheckedContinuation { continuation in
            jsonConfig(
                preferenceCenterID: preferenceCenterID
            ) { config in
                continuation.resume(returning: config)
            }
        }
    }
}
