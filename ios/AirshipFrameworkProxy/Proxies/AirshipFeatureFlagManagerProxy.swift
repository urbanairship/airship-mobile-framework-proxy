/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public class AirshipFeatureFlagManagerProxy {
    private let featureFlagManagerProvider: () throws -> FeatureFlagManager

    private var featureFlagManager: FeatureFlagManager {
        get throws { try featureFlagManagerProvider() }
    }

    init(featureFlagManagerProvider: @escaping () throws -> FeatureFlagManager) {
        self.featureFlagManagerProvider = featureFlagManagerProvider
    }

    public func flag(name: String) async throws -> FeatureFlagProxy {
        let flag = try await self.featureFlagManager.flag(name: name)
        return FeatureFlagProxy(flag: flag)
    }

    public func trackInteraction(flag: FeatureFlagProxy) throws {
        try self.featureFlagManager.trackInteraction(flag: flag.original)
    }
}

// We encode `isEligible` as snake case breaking the APIs for react. This
// wraps it so we can return camelCase like all other APIs.
public struct FeatureFlagProxy: Codable {
    let isEligible: Bool
    let exists: Bool
    let variables: AirshipJSON?
    let original: FeatureFlag

    init(flag: FeatureFlag) {
        self.isEligible = flag.isEligible
        self.exists = flag.exists
        self.variables = flag.variables
        self.original = flag
    }

    enum CodingKeys: String, CodingKey {
        case isEligible
        case exists
        case variables
        case original = "_internal"
    }
}


