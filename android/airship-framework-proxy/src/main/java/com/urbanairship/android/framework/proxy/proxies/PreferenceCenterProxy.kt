package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.PendingResult
import com.urbanairship.android.framework.proxy.ProxyStore
import com.urbanairship.json.JsonValue
import com.urbanairship.preferencecenter.PreferenceCenter

public class PreferenceCenterProxy internal constructor(
    private val proxyStore: ProxyStore,
    private val preferenceCenterProvider: () -> PreferenceCenter
) {

    public fun displayPreferenceCenter(preferenceCenterId: String) {
        preferenceCenterProvider().open(preferenceCenterId)
    }

    public fun getPreferenceCenterConfig(preferenceCenterId: String): PendingResult<JsonValue> {
        return preferenceCenterProvider().getJsonConfig(preferenceCenterId)
    }

    public fun setAutoLaunchPreferenceCenter(preferenceID: String, autoLaunch: Boolean) {
        proxyStore.setAutoLaunchPreferenceCenter(preferenceID, autoLaunch)
    }
}