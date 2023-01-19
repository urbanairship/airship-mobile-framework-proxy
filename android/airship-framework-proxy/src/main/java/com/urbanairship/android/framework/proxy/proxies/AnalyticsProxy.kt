package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.analytics.Analytics

public class AnalyticsProxy(private val analyticsProvider: () -> Analytics) {
    public fun associateIdentifier(key: String, value: String?) {
        val editor = analyticsProvider().editAssociatedIdentifiers()
        if (value == null) {
            editor.removeIdentifier(key)
        } else {
            editor.addIdentifier(key, value)
        }
        editor.apply()
    }

    public fun trackScreen(screen: String?) {
        analyticsProvider().trackScreen(screen)
    }
}