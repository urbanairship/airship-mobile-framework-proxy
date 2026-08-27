/* Copyright Airship and Contributors */

package com.urbanairship.android.framework.proxy.proxies

import android.annotation.SuppressLint
import android.content.Context
import com.urbanairship.Airship
import com.urbanairship.Autopilot
import com.urbanairship.UALog
import com.urbanairship.actions.DefaultActionRunner
import com.urbanairship.android.framework.proxy.LaunchDeepLinkTracker
import com.urbanairship.android.framework.proxy.ProxyConfig
import com.urbanairship.android.framework.proxy.ProxyStore
import com.urbanairship.automation.inAppAutomation
import com.urbanairship.featureflag.FeatureFlagManager
import com.urbanairship.json.JsonValue
import com.urbanairship.liveupdate.liveUpdateManager
import com.urbanairship.messagecenter.messageCenter
import com.urbanairship.preferencecenter.preferenceCenter

public class AirshipProxy(private val context: Context, internal val proxyStore: ProxyStore) {

    public val actions: ActionProxy = ActionProxy {
        ensureTakeOff()
        DefaultActionRunner
    }

    public val analytics: AnalyticsProxy = AnalyticsProxy {
        ensureTakeOff()
        Airship.analytics
    }

    public val channel: ChannelProxy = ChannelProxy {
        ensureTakeOff()
        Airship.channel
    }

    public val contact: ContactProxy = ContactProxy {
        ensureTakeOff()
        Airship.contact
    }

    public val inApp: InAppProxy = InAppProxy {
        ensureTakeOff()
        Airship.inAppAutomation
    }

    public val locale: LocaleProxy = LocaleProxy {
        ensureTakeOff()
        Airship.localeManager
    }

    public val liveUpdateManager: LiveUpdatesManagerProxy = LiveUpdatesManagerProxy {
        ensureTakeOff()
        Airship.liveUpdateManager
    }

    public val messageCenter: MessageCenterProxy = MessageCenterProxy(proxyStore) {
        ensureTakeOff()
        Airship.messageCenter
    }

    public val preferenceCenter: PreferenceCenterProxy = PreferenceCenterProxy(proxyStore) {
        ensureTakeOff()
        Airship.preferenceCenter
    }

    public val privacyManager: PrivacyManagerProxy = PrivacyManagerProxy {
        ensureTakeOff()
        Airship.privacyManager
    }

    public val push: PushProxy = PushProxy(
        context,
        proxyStore,
        permissionsManagerProvider = {
            ensureTakeOff()
            Airship.permissionsManager
        },
        pushProvider = {
            ensureTakeOff()
            Airship.push
        }
    )

    public val featureFlagManager: FeatureFlagManagerProxy = FeatureFlagManagerProxy {
        ensureTakeOff()
        FeatureFlagManager.shared()
    }

    public fun takeOff(config: JsonValue): Boolean = takeOff(ProxyConfig(config.optMap()))

    public fun takeOff(config: ProxyConfig): Boolean {
        UALog.v { "TakeOff requested with config=$config" }
        proxyStore.airshipConfig = config
        Autopilot.automaticTakeOff(context)
        val flying = isFlying()
        UALog.v { "TakeOff completed, isFlying=$flying" }
        return flying
    }

    public fun isFlying(): Boolean = Airship.isFlyingOrTakingOff

    /**
     * Returns the deep link that launched the app from a notification tap,
     * or null if the app was not launched by a deep-link-carrying tap.
     * One-shot: the value is consumed on read.
     */
    public suspend fun getLaunchDeepLink(): String? = LaunchDeepLinkTracker.shared().takeLaunchDeepLink()

    public companion object {
        @SuppressLint("StaticFieldLeak")
        @Volatile
        private var sharedInstance: AirshipProxy? = null
        private val sharedInstanceLock = Any()

        @JvmStatic
        public fun shared(context: Context): AirshipProxy {
            synchronized(sharedInstanceLock) {
                if (sharedInstance == null) {
                    sharedInstance = AirshipProxy(context.applicationContext, ProxyStore(context.applicationContext))
                }
                return sharedInstance!!
            }
        }
    }

    private fun ensureTakeOff() {
        if (!Airship.isFlyingOrTakingOff) {
            UALog.w { "TakeOff not called. Ensure Airship.takeOff() has completed before using proxy APIs." }
            throw java.lang.IllegalStateException("Takeoff not called.")
        }
    }
}
