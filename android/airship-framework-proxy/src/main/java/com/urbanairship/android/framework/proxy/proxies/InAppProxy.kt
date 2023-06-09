package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.android.framework.proxy.ProxyStore
import com.urbanairship.automation.InAppAutomation
import java.util.concurrent.TimeUnit

public class InAppProxy internal constructor(
    private val proxyStore: ProxyStore,
    private val inAppProvider: () -> InAppAutomation
) {

    public fun setAutoPauseOnLaunch(enabled: Boolean) {
        proxyStore.isAutoPauseOnLaunch = enabled
        setPaused(enabled)
    }

    public fun setPaused(paused: Boolean) {
        inAppProvider().isPaused = paused
    }

    public fun isPaused(): Boolean {
        return inAppProvider().isPaused
    }

    public fun setDisplayInterval(milliseconds: Long) {
        inAppProvider().inAppMessageManager.setDisplayInterval(milliseconds, TimeUnit.MILLISECONDS)
    }

    public fun getDisplayInterval(): Long {
        return inAppProvider().inAppMessageManager.displayInterval
    }
}
