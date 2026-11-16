/* Copyright Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Context
import android.os.Bundle
import androidx.test.core.app.ApplicationProvider
import com.urbanairship.AirshipConfigOptions
import com.urbanairship.android.framework.proxy.proxies.AirshipProxy
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

@RunWith(RobolectricTestRunner::class)
public class BaseAutopilotTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private lateinit var autopilot: TestAutopilot

    @Before
    public fun setUp() {
        resetSharedProxy()
        TestExtender.created = 0
        autopilot = TestAutopilot()
    }

    @Test
    public fun testInvalidConfigIsBuiltOnce() {
        assertFalse(autopilot.isReady(context))
        assertFalse(autopilot.isReady(context))
        assertFalse(autopilot.isReady(context))

        assertEquals(1, autopilot.configBuilds)
    }

    @Test
    public fun testStoredConfigChangeForcesARebuild() {
        assertFalse(autopilot.isReady(context))
        assertEquals(1, autopilot.configBuilds)

        AirshipProxy.shared(context).proxyStore.airshipConfig =
            ProxyConfig(site = AirshipConfigOptions.Site.SITE_EU)

        assertFalse(autopilot.isReady(context))
        assertEquals(2, autopilot.configBuilds)
    }

    @Test
    public fun testValidConfigIsAcceptedAndRetained() {
        autopilot.isConfigValid = true

        assertTrue(autopilot.isReady(context))
        assertEquals(1, autopilot.configBuilds)
        assertNotNull(autopilot.createAirshipConfigOptions(context))
    }

    @Test
    public fun testExtenderIsCreatedOnceAndKeepsConfigRebuilding() {
        installExtender()

        assertFalse(autopilot.isReady(context))
        assertFalse(autopilot.isReady(context))

        assertEquals(1, TestExtender.created)
        assertEquals(2, autopilot.configBuilds)
    }

    private fun installExtender() {
        val packageInfo = shadowOf(context.packageManager)
            .getInternalMutablePackageInfo(context.packageName)

        packageInfo.applicationInfo?.metaData = Bundle().apply {
            putString("com.urbanairship.plugin.extender", TestExtender::class.java.name)
        }
    }

    private fun resetSharedProxy() {
        val field = AirshipProxy::class.java.getDeclaredField("sharedInstance")
        field.isAccessible = true
        field.set(null, null)
    }

    private class TestAutopilot : BaseAutopilot() {

        var configBuilds: Int = 0
        var isConfigValid: Boolean = false

        override fun createConfigBuilder(context: Context): AirshipConfigOptions.Builder {
            configBuilds++

            return AirshipConfigOptions.newBuilder().apply {
                if (isConfigValid) {
                    setAppKey(VALID_APP_KEY)
                    setAppSecret(VALID_APP_SECRET)
                    setInProduction(false)
                    setDevelopmentAppKey(VALID_APP_KEY)
                    setDevelopmentAppSecret(VALID_APP_SECRET)
                }
            }
        }

        override fun onReady(context: Context) {}

        override fun onMigrateData(context: Context, proxyStore: ProxyStore) {}
    }

    public class TestExtender : AirshipPluginExtender {

        init {
            created++
        }

        override fun onAirshipReady(context: Context) {}

        override fun extendConfig(
            context: Context,
            configBuilder: AirshipConfigOptions.Builder
        ): AirshipConfigOptions.Builder = configBuilder

        public companion object {
            public var created: Int = 0
        }
    }

    private companion object {
        const val VALID_APP_KEY = "aaaaaaaaaaaaaaaaaaaaaa"
        const val VALID_APP_SECRET = "bbbbbbbbbbbbbbbbbbbbbb"
    }
}
