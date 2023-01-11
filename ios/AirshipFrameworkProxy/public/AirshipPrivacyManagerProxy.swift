/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public class AirshipPrivacyManagerProxy {

    private let privacyManagerProvider: () throws -> AirshipPrivacyManagerProtocol
    private var privacyManager: AirshipPrivacyManagerProtocol {
        get throws { try privacyManagerProvider() }
    }

    init(
        privacyManagerProvider: @escaping () throws -> AirshipPrivacyManagerProtocol
    ) {
        self.privacyManagerProvider = privacyManagerProvider
    }

    func setEnabledFeatures(
        _ features: [Any]
    ) throws {
        let features = try Features.parse(features)
        try self.privacyManager.enabledFeatures = features
    }

    func getEnabledFeatures(
    ) throws -> [String] {
        return try self.privacyManager.enabledFeatures.names
    }

    func enableFeature(
        _ features: [Any]
    ) throws {
        let features = try Features.parse(features)
        try self.privacyManager.enableFeatures(
            features
        )
    }

    public func disableFeature(
        _ features: [Features]
    ) throws {
        let features = try Features.parse(features)
        try self.privacyManager.disableFeatures(
            features
        )
    }

    public func isFeatureEnabled(
        _ features: [Features]
    ) throws -> Bool {
        let features = try Features.parse(features)
        return try self.privacyManager.isEnabled(
            features
        )
    }
}

protocol AirshipPrivacyManagerProtocol: AnyObject {
    var enabledFeatures: Features { get set}
    func enableFeatures(_ features: Features)
    func disableFeatures(_ features: Features)
    func isEnabled(_ feature: Features) -> Bool
}

extension PrivacyManager: AirshipPrivacyManagerProtocol {}
