/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import androidx.annotation.XmlRes
import com.urbanairship.Airship
import com.urbanairship.AirshipConfigOptions
import com.urbanairship.Autopilot
import com.urbanairship.UALog
import com.urbanairship.Predicate
import com.urbanairship.android.framework.proxy.Utils.getNamedResource
import com.urbanairship.android.framework.proxy.events.EventEmitter
import com.urbanairship.android.framework.proxy.events.NotificationStatusEvent
import com.urbanairship.android.framework.proxy.events.PendingEmbeddedUpdated
import com.urbanairship.android.framework.proxy.proxies.AirshipProxy
import com.urbanairship.messagecenter.MessageCenter
import com.urbanairship.permission.Permission
import com.urbanairship.preferencecenter.PreferenceCenter
import com.urbanairship.push.pushNotificationStatusFlow
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import androidx.core.net.toUri

/**
 * Module's autopilot to customize Urban Airship.
 */
public abstract class BaseAutopilot : Autopilot() {

    private var extenderProvider: ExtenderProvider = ExtenderProvider()
    private var configOptions: AirshipConfigOptions? = null
    private var firstReady: Boolean = false

    private val dispatcher = CoroutineScope(Dispatchers.Main + SupervisorJob())

    final override fun onAirshipReady(context: Context) {
        UALog.v { "Airship ready, registering listeners and applying notification config" }

        val proxyStore = AirshipProxy.shared(context).proxyStore
        val airshipListener = AirshipListener(
            AirshipProxy.shared(context).proxyStore,
            EventEmitter.shared()
        )

        PreferenceCenter.shared().openListener = airshipListener
        MessageCenter.shared().setOnShowMessageCenterListener(airshipListener)
        MessageCenter.shared().inbox.addListener(airshipListener)

        Airship.channel.addChannelListener(airshipListener)
        Airship.push.addPushListener(airshipListener)
        Airship.push.addPushTokenListener(airshipListener)
        Airship.push.notificationListener = airshipListener
        Airship.deepLinkListener = airshipListener

        dispatcher.launch {
            PendingEmbedded.pending.collect {
                EventEmitter.shared().addEvent(
                    PendingEmbeddedUpdated(it),
                    true
                )
            }
        }

        dispatcher.launch {
            combine(
                Airship.push.pushNotificationStatusFlow,
                Airship.permissionsManager.permissionsUpdate(Permission.DISPLAY_NOTIFICATIONS)
            ) { status, permissionStatus ->
                NotificationStatus(status, permissionStatus.value)
            }.filter {
                it != proxyStore.lastNotificationStatus
            }.collect {
                proxyStore.lastNotificationStatus = it
                EventEmitter.shared().addEvent(
                    NotificationStatusEvent(it),
                    replacePending = true
                )
            }
        }

        // Set our custom notification provider
        val notificationProvider = BaseNotificationProvider(context, Airship.airshipConfigOptions)
        notificationProvider.applyNotificationConfig(proxyStore.notificationConfig)
        Airship.push.notificationProvider = notificationProvider
        Airship.push.foregroundNotificationDisplayPredicate = Predicate { message ->
            return@Predicate runBlocking {
                val override = AirshipPluginExtensions.onShouldDisplayForegroundNotification?.invoke(message) ?: AirshipPluginOverride.UseDefault
                return@runBlocking when(override) {
                    is AirshipPluginOverride.Override -> {
                        override.result
                    }
                    is AirshipPluginOverride.UseDefault -> {
                        AirshipProxy.shared(context).push.foregroundNotificationDisplayPredicate?.apply(
                            Utils.notificationMap(
                                message
                            )
                        ) ?: proxyStore.isForegroundNotificationsEnabled
                    }
                }
            }
        }

        loadCustomNotificationChannels(context)
        loadCustomNotificationButtonGroups(context)

        UALog.v { "Notification config and listeners applied" }
        onReady(context)

        extenderProvider.get(context)?.onAirshipReady(context)
        extenderProvider.reset()
    }

    protected abstract fun onReady(context: Context)

    @SuppressLint("DiscouragedApi")
    private fun loadCustomNotificationChannels(context: Context) {
        val packageName = context.packageName
        @XmlRes val resId = context.resources.getIdentifier("ua_custom_notification_channels", "xml", packageName)

        if (resId != 0) {
            UALog.d { "Loading custom notification channels" }
            Airship.push.notificationChannelRegistry.createNotificationChannels(resId)
        }
    }

    @SuppressLint("DiscouragedApi")
    private fun loadCustomNotificationButtonGroups(context: Context) {
        val packageName = context.packageName
        @XmlRes val resId = context.resources.getIdentifier("ua_custom_notification_buttons", "xml", packageName)

        if (resId != 0) {
            UALog.d { "Loading custom notification button groups" }
            Airship.push.addNotificationActionButtonGroups(context, resId)
        }
    }

    override fun isReady(context: Context): Boolean {
        if (!firstReady) {
            onMigrateData(context, AirshipProxy.shared(context).proxyStore)
            firstReady = true
        }

        var builder = createConfigBuilder(context)
        AirshipProxy.shared(context).proxyStore.airshipConfig?.let {
            UALog.v { "Applying proxy config to Airship config" }
            builder.applyProxyConfig(context, it)
        }

        builder = extenderProvider.get(context)?.extendConfig(context, builder) ?: builder

        val configOptions = builder.build()

        return try {
            configOptions.validate()
            this.configOptions = configOptions
            UALog.i { "Airship config validated successfully" }
            true
        } catch (e: Exception) {
            UALog.w { "Airship config validation failed: ${e.message}" }
            false
        }
    }

    public open fun createConfigBuilder(context: Context): AirshipConfigOptions.Builder {
        return AirshipConfigOptions.newBuilder()
            .let {
                try {
                    it.tryApplyDefaultProperties(context)
                } catch (e: Exception) {
                    UALog.v { "Failed to load config from properties file: ${e.message}" }
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
    proxyConfig.developmentEnvironment?.let {
        this.setDevelopmentAppKey(it.appKey)
            .setDevelopmentAppSecret(it.appSecret)
            .setDevelopmentLogLevel(it.logLevel ?: AirshipConfigOptions.LogLevel.DEBUG)

        proxyConfig.androidConfig?.logPrivacyLevel?.let { privacyLevel ->
            this.setDevelopmentLogPrivacyLevel(privacyLevel)
        }
    }

    proxyConfig.productionEnvironment?.let {
        this.setProductionAppKey(it.appKey)
            .setProductionAppSecret(it.appSecret)
            .setProductionLogLevel(it.logLevel ?: AirshipConfigOptions.LogLevel.ERROR)

        proxyConfig.androidConfig?.logPrivacyLevel?.let { privacyLevel ->
            this.setProductionLogPrivacyLevel(privacyLevel)
        }
    }

    proxyConfig.defaultEnvironment?.let {
        this.setAppKey(it.appKey)
            .setAppSecret(it.appSecret)
            .setLogLevel(it.logLevel ?: AirshipConfigOptions.LogLevel.ERROR)
    }

    proxyConfig.site?.let { this.setSite(it) }
    proxyConfig.inProduction?.let { this.setInProduction(it) }
    proxyConfig.isChannelCreationDelayEnabled?.let { this.setChannelCreationDelayEnabled(it) }
    proxyConfig.isChannelCaptureEnabled?.let { this.setChannelCaptureEnabled(it) }
    proxyConfig.initialConfigUrl?.let { this.setInitialConfigUrl(it) }
    proxyConfig.urlAllowList?.let { this.setUrlAllowList(it.toTypedArray()) }
    proxyConfig.urlAllowListScopeJavaScriptInterface?.let { this.setUrlAllowListScopeJavaScriptInterface(it.toTypedArray()) }
    proxyConfig.urlAllowListScopeOpenUrl?.let { this.setUrlAllowListScopeOpenUrl(it.toTypedArray()) }
    proxyConfig.androidConfig?.appStoreUri?.let { this.setAppStoreUri(it.toUri()) }
    proxyConfig.androidConfig?.fcmFirebaseAppName?.let { this.setFcmFirebaseAppName(it) }
    proxyConfig.enabledFeatures?.let { this.setEnabledFeatures(it) }
    proxyConfig.autoPauseInAppAutomationOnLaunch?.let { this.setAutoPauseInAppAutomationOnLaunch(it) }

    proxyConfig.androidConfig?.notificationConfig?.let { notificationConfig ->
        notificationConfig.icon?.let {
            val resourceId = getNamedResource(context, it, "drawable")
            this.setNotificationIcon(resourceId)
        }

        notificationConfig.largeIcon?.let {
            val resourceId = getNamedResource(context, it, "drawable")
            this.setNotificationLargeIcon(resourceId)
        }

        notificationConfig.defaultChannelId?.let { this.setNotificationChannel(it) }
        notificationConfig.accentColor?.let { this.setNotificationAccentColor(Utils.getHexColor(it, 0)) }
    }
}

private class ExtenderProvider {
    private var extender: AirshipPluginExtender? = null
    private var created: Boolean = false

    fun get(context: Context): AirshipPluginExtender? {
        if (!created) {
            extender = createExtender(context)
        }
        return extender
    }

    fun reset() {
        created = false
        extender = null
    }

    private fun createExtender(context: Context): AirshipPluginExtender? {
        val ai: ApplicationInfo
        try {
            ai = context.packageManager.getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)

            if (ai.metaData == null) {
                return null
            }
        } catch (_: PackageManager.NameNotFoundException) {
            return null
        }

        val classname = ai.metaData.getString(EXTENDER_MANIFEST_KEY) ?: return null

        try {
            val extenderClass = Class.forName(classname)
            return extenderClass.getDeclaredConstructor().newInstance() as AirshipPluginExtender
        } catch (e: Exception) {
            UALog.e(e) { "Unable to create extender: $classname" }
        }
        return null
    }

    private companion object {
        const val EXTENDER_MANIFEST_KEY = "com.urbanairship.plugin.extender"
    }
}


