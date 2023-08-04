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

    public func flag(name: String) async throws -> FeatureFlag {
        return try await self.featureFlagManager.flag(name: name)
    }
}
