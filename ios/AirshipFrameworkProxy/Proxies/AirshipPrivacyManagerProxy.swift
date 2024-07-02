/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

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

    public func setEnabled(
        featureNames: [String]
    ) throws {
        let features = try AirshipFeature.parse(featureNames)
        try self.privacyManager.enabledFeatures = features
    }

    public func setEnabled(
        features: AirshipFeature
    ) throws {
        try self.privacyManager.enabledFeatures = features
    }

    public func getEnabledNames(
    ) throws -> [String] {
        return try self.privacyManager.enabledFeatures.names
    }

    public func getEnabled(
    ) throws -> AirshipFeature {
        return try self.privacyManager.enabledFeatures
    }

    public func enable(
        featureNames: [String]
    ) throws {
        let features = try AirshipFeature.parse(featureNames)
        try self.privacyManager.enableFeatures(
            features
        )
    }

    public func enable(
        features: AirshipFeature
    ) throws {
        try self.privacyManager.enableFeatures(
            features
        )
    }

    public func disable(
        featureNames: [String]
    ) throws {
        let features = try AirshipFeature.parse(featureNames)
        try self.privacyManager.disableFeatures(
            features
        )
    }

    public func disable(
        _ features: AirshipFeature
    ) throws {
        try self.privacyManager.disableFeatures(
            features
        )
    }

    public func isEnabled(
        featuresNames: [String]
    ) throws -> Bool {
        let features = try AirshipFeature.parse(featuresNames)
        return try self.privacyManager.isEnabled(
            features
        )
    }

    public func isEnabled(
        features: AirshipFeature
    ) throws -> Bool {
        return try self.privacyManager.isEnabled(
            features
        )
    }
}

protocol AirshipPrivacyManagerProtocol: AnyObject {
    var enabledFeatures: AirshipFeature { get set}
    func enableFeatures(_ features: AirshipFeature)
    func disableFeatures(_ features: AirshipFeature)
    func isEnabled(_ feature: AirshipFeature) -> Bool
}

extension AirshipPrivacyManager: AirshipPrivacyManagerProtocol {}
