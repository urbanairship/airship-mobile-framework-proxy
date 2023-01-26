/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.annotation.XmlRes
import com.urbanairship.AirshipConfigOptions
import com.urbanairship.Autopilot
import com.urbanairship.UAirship
import com.urbanairship.android.framework.proxy.events.EventEmitter
import com.urbanairship.android.framework.proxy.proxies.AirshipProxy
import com.urbanairship.app.GlobalActivityMonitor
import com.urbanairship.messagecenter.MessageCenter
import com.urbanairship.preferencecenter.PreferenceCenter


/**
 * Module's autopilot to customize Urban Airship.
 */
public abstract class BaseAutopilot : Autopilot() {

    private var configOptions: AirshipConfigOptions? = null
    private var firstReady: Boolean = false

    override fun onAirshipReady(airship: UAirship) {
        super.onAirshipReady(airship)

        ProxyLogger.setLogLevel(airship.airshipConfigOptions.logLevel)
        val context = UAirship.getApplicationContext()

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
        airship.permissionsManager.addOnPermissionStatusChangedListener(airshipListener)

        // Set our custom notification provider
        val notificationProvider = BaseNotificationProvider(context, airship.airshipConfigOptions)
        airship.pushManager.notificationProvider = notificationProvider

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
            builder.applyProxyConfig(it)
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
            .applyDefaultProperties(context)
            .setRequireInitialRemoteConfigEnabled(true)
    }

    override fun createAirshipConfigOptions(context: Context): AirshipConfigOptions? {
        return configOptions
    }

    public abstract fun onMigrateData(context: Context, proxyStore: ProxyStore)
}

internal fun AirshipConfigOptions.Builder.applyProxyConfig(proxyConfig: ProxyConfig) {
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
    proxyConfig?.initialConfigUrl?.let { this.setInitialConfigUrl(it) }
    proxyConfig?.urlAllowList?.let { this.setUrlAllowList(it.toTypedArray()) }
    proxyConfig?.urlAllowListScopeJavaScriptInterface?.let { this.setUrlAllowListScopeJavaScriptInterface(it.toTypedArray()) }
    proxyConfig?.urlAllowListScopeOpenUrl?.let { this.setUrlAllowListScopeOpenUrl(it.toTypedArray()) }
    proxyConfig?.androidConfig?.appStoreUri?.let { this.setAppStoreUri(Uri.parse(it)) }
    proxyConfig?.androidConfig?.fcmFirebaseAppName?.let { this.setFcmFirebaseAppName(it) }
    proxyConfig?.enabledFeatures?.let { this.setEnabledFeatures(it) }
}