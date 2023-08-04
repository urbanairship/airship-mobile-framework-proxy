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
        return FeatureFlagProxy(isElegible: flag.isEligible, exists: flag.exists, variables: flag.variables)
        
    }
}

// We encode `isElegible` as snake case breaking the APIs for react. This
// wraps it so we can return camelCase like all other APIs.
public struct FeatureFlagProxy: Codable {
    let isElegible: Bool
    let exists: Bool
    let variables: AirshipJSON?
}


