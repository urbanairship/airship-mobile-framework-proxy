package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.featureflag.FeatureFlagManager
import com.urbanairship.json.JsonValue
import com.urbanairship.json.jsonMapOf

public class FeatureFlagManagerProxy internal constructor(private val featureFlagManagerProvider: () -> FeatureFlagManager) {
    public suspend fun flag(name: String): JsonValue {
        val flag = featureFlagManagerProvider().flag(name).getOrThrow()
        return jsonMapOf(
            "isEligible" to flag.isEligible,
            "exists" to flag.exists,
            "variables" to flag.variables
        ).toJsonValue()
    }
}
