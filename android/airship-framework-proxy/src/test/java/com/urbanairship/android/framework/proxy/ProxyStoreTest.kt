/* Copyright Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.urbanairship.AirshipConfigOptions
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
public class ProxyStoreTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val store = ProxyStore(context)

    @Test
    public fun testNotificationConfigReflectsLastWrite() {
        val first = NotificationConfig("first", null, null, null)
        val second = NotificationConfig("second", null, null, null)

        store.notificationConfig = first
        assertEquals(first, store.notificationConfig)

        store.notificationConfig = second
        assertEquals(second, store.notificationConfig)
    }

    @Test
    public fun testAirshipConfigReflectsLastWrite() {
        val first = ProxyConfig(site = AirshipConfigOptions.Site.SITE_US)
        val second = ProxyConfig(site = AirshipConfigOptions.Site.SITE_EU)

        store.airshipConfig = first
        assertEquals(first, store.airshipConfig)

        store.airshipConfig = second
        assertEquals(second, store.airshipConfig)
    }

    @Test
    public fun testLastNotificationStatusReflectsLastWrite() {
        val first = notificationStatus(isOptedIn = false)
        val second = notificationStatus(isOptedIn = true)

        store.lastNotificationStatus = first
        assertEquals(first, store.lastNotificationStatus)

        store.lastNotificationStatus = second
        assertEquals(second, store.lastNotificationStatus)
    }

    @Test
    public fun testClearingAConfigReturnsNull() {
        store.airshipConfig = ProxyConfig(site = AirshipConfigOptions.Site.SITE_US)
        assertEquals(ProxyConfig(site = AirshipConfigOptions.Site.SITE_US), store.airshipConfig)

        store.airshipConfig = null
        assertNull(store.airshipConfig)
    }

    @Test
    public fun testValuesSurviveANewStoreInstance() {
        val config = ProxyConfig(site = AirshipConfigOptions.Site.SITE_EU)
        store.airshipConfig = config

        assertEquals(config, ProxyStore(context).airshipConfig)
    }

    private fun notificationStatus(isOptedIn: Boolean) = NotificationStatus(
        isUserNotificationsEnabled = true,
        areNotificationsAllowed = true,
        isPushPrivacyFeatureEnabled = true,
        isPushTokenRegistered = true,
        isUserOptedIn = true,
        isOptedIn = isOptedIn,
        notificationPermissionStatus = null
    )
}
