package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.UALog
import com.urbanairship.android.framework.proxy.ProxyStore
import com.urbanairship.json.JsonValue
import com.urbanairship.preferencecenter.PreferenceCenter

public class PreferenceCenterProxy internal constructor(
    private val proxyStore: ProxyStore,
    private val preferenceCenterProvider: () -> PreferenceCenter
) {

    public fun displayPreferenceCenter(preferenceCenterId: String) {
        UALog.v { "displayPreferenceCenter called, preferenceCenterId=$preferenceCenterId" }
        preferenceCenterProvider().open(preferenceCenterId)
    }

    public suspend fun getPreferenceCenterConfig(preferenceCenterId: String): JsonValue? {
        UALog.v { "getPreferenceCenterConfig called, preferenceCenterId=$preferenceCenterId" }
        return preferenceCenterProvider().getJsonConfig(preferenceCenterId)
    }

    public fun setAutoLaunchPreferenceCenter(preferenceID: String, autoLaunch: Boolean) {
        UALog.v { "setAutoLaunchPreferenceCenter called, preferenceID=$preferenceID, autoLaunch=$autoLaunch" }
        proxyStore.setAutoLaunchPreferenceCenter(preferenceID, autoLaunch)
    }
}
