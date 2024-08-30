/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.annotation.XmlRes
import com.urbanairship.AirshipConfigOptions
import com.urbanairship.Autopilot
import com.urbanairship.Predicate
import com.urbanairship.UAirship
import com.urbanairship.android.framework.proxy.Utils.getHexColor
import com.urbanairship.android.framework.proxy.Utils.getNamedResource
import com.urbanairship.android.framework.proxy.events.EventEmitter
import com.urbanairship.android.framework.proxy.events.NotificationStatusEvent
import com.urbanairship.android.framework.proxy.events.PendingEmbeddedUpdated
import com.urbanairship.android.framework.proxy.proxies.AirshipProxy
import com.urbanairship.messagecenter.MessageCenter
import com.urbanairship.preferencecenter.PreferenceCenter
import com.urbanairship.push.pushNotificationStatusFlow
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

/**
 * Module's autopilot to customize Urban Airship.
 */
public abstract class BaseAutopilot : Autopilot() {

    private var configOptions: AirshipConfigOptions? = null
    private var firstReady: Boolean = false

    private val dispatcher = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun onAirshipReady(airship: UAirship) {
        super.onAirshipReady(airship)

        ProxyLogger.setLogLevel(airship.airshipConfigOptions.logLevel)
        val context = UAirship.getApplicationContext()

        val proxyStore = AirshipProxy.shared(context).proxyStore
        val airshipListener = AirshipListener(
            AirshipProxy.shared(context).proxyStore,
            EventEmitter.shared()
        )

        PreferenceCenter.shared().openListener = airshipListener
        MessageCenter.shared().setOnShowMessageCenterListener(airshipListener)
        MessageCenter.shared().inbox.addListener(airshipListener)

        airship.channel.addChannelListener(airshipListener)
        airship.pushManager.addPushListener(airshipListener)
        airship.pushManager.addPushTokenListener(airshipListener)
        airship.pushManager.notificationListener = airshipListener
        airship.deepLinkListener = airshipListener

        dispatcher.launch {
            PendingEmbedded.pending.collect {
                EventEmitter.shared().addEvent(
                    PendingEmbeddedUpdated(it),
                    true
                )
            }
        }

        dispatcher.launch {
            airship.pushManager.pushNotificationStatusFlow
                .map { NotificationStatus(it) }
                .filter { it != proxyStore.lastNotificationStatus }
                .collect {
                    proxyStore.lastNotificationStatus = it
                    EventEmitter.shared().addEvent(
                        NotificationStatusEvent(it),
                        replacePending = true
                    )
                }
        }


        // Set our custom notification provider
        val notificationProvider = BaseNotificationProvider(context, airship.airshipConfigOptions)
        airship.pushManager.notificationProvider = notificationProvider
        airship.pushManager.foregroundNotificationDisplayPredicate = Predicate { message ->
            AirshipProxy.shared(context).push.foregroundNotificationDisplayPredicate?.let { predicate ->
                runBlocking {
                    predicate.apply(Utils.notificationMap(message))
                }
            } ?: proxyStore.isForegroundNotificationsEnabled
        }
        loadCustomNotificationChannels(context, airship)
        loadCustomNotificationButtonGroups(context, airship)
    }

    private fun loadCustomNotificationChannels(context: Context, airship: UAirship) {
        val packageName = UAirship.getPackageName()
        @XmlRes val resId = context.resources.getIdentifier("ua_custom_notification_channels", "xml", packageName)

        if (resId != 0) {
            ProxyLogger.debug("Loading custom notification channels")
            airship.pushManager.notificationChannelRegistry.createNotificationChannels(resId)
        }
    }

    private fun loadCustomNotificationButtonGroups(context: Context, airship: UAirship) {
        val packageName = UAirship.getPackageName()
        @XmlRes val resId = context.resources.getIdentifier("ua_custom_notification_buttons", "xml", packageName)

        if (resId != 0) {
            ProxyLogger.debug("Loading custom notification button groups")
            airship.pushManager.addNotificationActionButtonGroups(context, resId)
        }
    }

    override fun isReady(context: Context): Boolean {
        if (!firstReady) {
            onMigrateData(context, AirshipProxy.shared(context).proxyStore)
            firstReady = true
        }

        val builder = createConfigBuilder(context)
        AirshipProxy.shared(context).proxyStore.airshipConfig?.let {
            builder.applyProxyConfig(context, it)
        }

        val configOptions = builder.build()

        return try {
            configOptions.validate()
            this.configOptions = configOptions
            true
        } catch (e: Exception) {
            false
        }
    }

    public open fun createConfigBuilder(context: Context): AirshipConfigOptions.Builder {
        return AirshipConfigOptions.newBuilder()
            .let {
                try {
                    it.tryApplyDefaultProperties(context)
                } catch (e: Exception) {
                    ProxyLogger.verbose("Failed to load config from properties file: " + e.message)
                }
                it
            }
            .setRequireInitialRemoteConfigEnabled(true)
    }

    override fun createAirshipConfigOptions(context: Context): AirshipConfigOptions? {
        return configOptions
    }

    public abstract fun onMigrateData(context: Context, proxyStore: ProxyStore)
}

public fun AirshipConfigOptions.Builder.applyProxyConfig(context: Context, proxyConfig: ProxyConfig) {
    proxyConfig?.developmentEnvironment?.let {
        this.setDevelopmentAppKey(it.appKey)
            .setDevelopmentAppSecret(it.appSecret)
            .setDevelopmentLogLevel(it.logLevel ?: Log.DEBUG)
    }

    proxyConfig?.productionEnvironment?.let {
        this.setProductionAppKey(it.appKey)
            .setProductionAppSecret(it.appSecret)
            .setProductionLogLevel(it.logLevel ?: Log.DEBUG)
    }

    proxyConfig?.defaultEnvironment?.let {
        this.setAppKey(it.appKey)
            .setAppSecret(it.appSecret)
            .setLogLevel(it.logLevel ?: Log.ERROR)
    }

    proxyConfig?.site?.let { this.setSite(it) }
    proxyConfig?.inProduction?.let { this.setInProduction(it) }
    proxyConfig?.isChannelCreationDelayEnabled?.let { this.setChannelCreationDelayEnabled(it) }
    proxyConfig?.isChannelCaptureEnabled?.let { this.setChannelCaptureEnabled(it) }
    proxyConfig?.initialConfigUrl?.let { this.setInitialConfigUrl(it) }
    proxyConfig?.urlAllowList?.let { this.setUrlAllowList(it.toTypedArray()) }
    proxyConfig?.urlAllowListScopeJavaScriptInterface?.let { this.setUrlAllowListScopeJavaScriptInterface(it.toTypedArray()) }
    proxyConfig?.urlAllowListScopeOpenUrl?.let { this.setUrlAllowListScopeOpenUrl(it.toTypedArray()) }
    proxyConfig?.androidConfig?.appStoreUri?.let { this.setAppStoreUri(Uri.parse(it)) }
    proxyConfig?.androidConfig?.fcmFirebaseAppName?.let { this.setFcmFirebaseAppName(it) }
    proxyConfig?.enabledFeatures?.let { this.setEnabledFeatures(it) }
    proxyConfig?.autoPauseInAppAutomationOnLaunch?.let { this.setAutoPauseInAppAutomationOnLaunch(it) }

    proxyConfig?.androidConfig?.notificationConfig?.let { notificationConfig ->
        notificationConfig.icon?.let {
            val resourceId = getNamedResource(context, it, "drawable")
            this.setNotificationIcon(resourceId)
        }

        notificationConfig.largeIcon?.let {
            val resourceId = getNamedResource(context, it, "drawable")
            this.setNotificationLargeIcon(resourceId)
        }

        notificationConfig.defaultChannelId?.let { this.setNotificationChannel(it) }
        notificationConfig.accentColor?.let { this.setNotificationAccentColor(getHexColor(it, 0)) }
    }
}
