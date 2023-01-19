/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

@objc
public class AirshipPrivacyManagerProxy: NSObject {

    private let privacyManagerProvider: () throws -> AirshipPrivacyManagerProtocol
    private var privacyManager: AirshipPrivacyManagerProtocol {
        get throws { try privacyManagerProvider() }
    }

    init(
        privacyManagerProvider: @escaping () throws -> AirshipPrivacyManagerProtocol
    ) {
        self.privacyManagerProvider = privacyManagerProvider
    }

    @objc
    func setEnabled(
        featureNames: [String]
    ) throws {
        let features = try Features.parse(featureNames)
        try self.privacyManager.enabledFeatures = features
    }

    @objc
    func setEnabled(
        features: Features
    ) throws {
        try self.privacyManager.enabledFeatures = features
    }

    @objc
    func getEnabled(
    ) throws -> [String] {
        return try self.privacyManager.enabledFeatures.names
    }

    func getEnabled(
    ) throws -> Features {
        return try self.privacyManager.enabledFeatures
    }

    @objc
    func enable(
        featureNames: [String]
    ) throws {
        let features = try Features.parse(featureNames)
        try self.privacyManager.enableFeatures(
            features
        )
    }

    @objc
    func enable(
        features: Features
    ) throws {
        try self.privacyManager.enableFeatures(
            features
        )
    }


    @objc
    public func disable(
        featureNames: [String]
    ) throws {
        let features = try Features.parse(featureNames)
        try self.privacyManager.disableFeatures(
            features
        )
    }

    @objc
    public func disable(
        _ features: Features
    ) throws {
        try self.privacyManager.disableFeatures(
            features
        )
    }

    @objc
    public func _isEnabled(
        featuresNames: [String]
    ) throws -> NSNumber {
        return try NSNumber(value: isEnabled(featuresNames: featuresNames))
    }

    public func isEnabled(
        featuresNames: [String]
    ) throws -> Bool {
        let features = try Features.parse(featuresNames)
        return try self.privacyManager.isEnabled(
            features
        )
    }

    public func isEnabled(
        features: Features
    ) throws -> Bool {
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
