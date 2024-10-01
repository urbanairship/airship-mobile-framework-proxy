/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.proxies

import android.annotation.SuppressLint
import android.content.Context
import com.urbanairship.Autopilot
import com.urbanairship.UAirship
import com.urbanairship.actions.DefaultActionRunner
import com.urbanairship.android.framework.proxy.ProxyConfig
import com.urbanairship.android.framework.proxy.ProxyStore
import com.urbanairship.automation.InAppAutomation
import com.urbanairship.featureflag.FeatureFlagManager
import com.urbanairship.json.JsonValue
import com.urbanairship.liveupdate.LiveUpdateManager
import com.urbanairship.messagecenter.MessageCenter
import com.urbanairship.preferencecenter.PreferenceCenter

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
        UAirship.shared().analytics
    }

    public val channel: ChannelProxy = ChannelProxy {
        ensureTakeOff()
        UAirship.shared().channel
    }

    public val contact: ContactProxy = ContactProxy {
        ensureTakeOff()
        UAirship.shared().contact
    }

    public val inApp: InAppProxy = InAppProxy {
        ensureTakeOff()
        InAppAutomation.shared()
    }

    public val locale: LocaleProxy = LocaleProxy {
        ensureTakeOff()
        UAirship.shared().localeManager
    }

    public val liveUpdateManager: LiveUpdatesManagerProxy = LiveUpdatesManagerProxy {
        ensureTakeOff()
        LiveUpdateManager.shared()
    }

    public val messageCenter: MessageCenterProxy = MessageCenterProxy(proxyStore) {
        ensureTakeOff()
        MessageCenter.shared()
    }

    public val preferenceCenter: PreferenceCenterProxy = PreferenceCenterProxy(proxyStore) {
        ensureTakeOff()
        PreferenceCenter.shared()
    }

    public val privacyManager: PrivacyManagerProxy = PrivacyManagerProxy() {
        ensureTakeOff()
        UAirship.shared().privacyManager
    }

    public val push: PushProxy = PushProxy(
        context,
        proxyStore,
        permissionsManagerProvider = {
            ensureTakeOff()
            UAirship.shared().permissionsManager
        },
        pushProvider = {
            ensureTakeOff()
            UAirship.shared().pushManager
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
        return UAirship.isFlying() || UAirship.isTakingOff()
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
        if (!UAirship.isFlying() && !UAirship.isTakingOff()) {
            throw java.lang.IllegalStateException("Takeoff not called.")
        }
    }
}
