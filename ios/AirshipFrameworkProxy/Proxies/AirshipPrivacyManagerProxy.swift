/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
public import AirshipKit
#elseif canImport(AirshipCore)
public import AirshipCore
#endif

public final class AirshipPrivacyManagerProxy: Sendable {

    private let privacyManagerProvider: @Sendable () throws -> any AirshipPrivacyManager
    private var privacyManager: any AirshipPrivacyManager {
        get throws { try privacyManagerProvider() }
    }

    init(
        privacyManagerProvider: @Sendable @escaping () throws -> any AirshipPrivacyManager
    ) {
        self.privacyManagerProvider = privacyManagerProvider
    }

    public func setEnabled(
        featureNames: [String]
    ) throws {
        AirshipLogger.trace("setEnabled called, featureNames=\(featureNames)")
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
        AirshipLogger.trace("getEnabledNames called")
        return try self.privacyManager.enabledFeatures.names
    }

    public func getEnabled(
    ) throws -> AirshipFeature {
        return try self.privacyManager.enabledFeatures
    }

    public func enable(
        featureNames: [String]
    ) throws {
        AirshipLogger.trace("enable called, featureNames=\(featureNames)")
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
        AirshipLogger.trace("disable called, featureNames=\(featureNames)")
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
        AirshipLogger.trace("isEnabled called, featuresNames=\(featuresNames)")
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
