/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.proxies

import android.annotation.SuppressLint
import android.content.Context
import com.urbanairship.Airship
import com.urbanairship.Autopilot
import com.urbanairship.actions.DefaultActionRunner
import com.urbanairship.android.framework.proxy.ProxyConfig
import com.urbanairship.android.framework.proxy.ProxyStore
import com.urbanairship.automation.inAppAutomation
import com.urbanairship.featureflag.FeatureFlagManager
import com.urbanairship.json.JsonValue
import com.urbanairship.liveupdate.liveUpdateManager
import com.urbanairship.messagecenter.messageCenter
import com.urbanairship.preferencecenter.preferenceCenter

public class AirshipProxy(
    private val context: Context,
    internal val proxyStore: ProxyStore
) {

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

    public val privacyManager: PrivacyManagerProxy = PrivacyManagerProxy() {
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

    public val featureFlagManager: FeatureFlagManagerProxy = FeatureFlagManagerProxy() {
        ensureTakeOff()
        FeatureFlagManager.shared()
    }

    public fun takeOff(config: JsonValue): Boolean {
        return takeOff(ProxyConfig(config.optMap()))
    }

    public fun takeOff(config: ProxyConfig): Boolean {
        proxyStore.airshipConfig = config
        Autopilot.automaticTakeOff(context)
        return isFlying()
    }

    public fun isFlying(): Boolean {
        return Airship.isFlyingOrTakingOff
    }

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
            throw java.lang.IllegalStateException("Takeoff not called.")
        }
    }
}
