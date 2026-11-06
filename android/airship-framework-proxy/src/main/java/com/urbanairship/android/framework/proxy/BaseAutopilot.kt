/* Copyright Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import androidx.annotation.XmlRes
import androidx.core.net.toUri
import com.urbanairship.Airship
import com.urbanairship.AirshipConfigOptions
import com.urbanairship.Autopilot
import com.urbanairship.Predicate
import com.urbanairship.UALog
import com.urbanairship.android.framework.proxy.Utils.getNamedResource
import com.urbanairship.android.framework.proxy.events.EventEmitter
import com.urbanairship.android.framework.proxy.events.FeatureFlagStatusChangedEvent
import com.urbanairship.android.framework.proxy.events.NotificationStatusEvent
import com.urbanairship.android.framework.proxy.events.PendingEmbeddedUpdated
import com.urbanairship.android.framework.proxy.proxies.AirshipProxy
import com.urbanairship.android.framework.proxy.proxies.toProxyString
import com.urbanairship.app.ApplicationListener
import com.urbanairship.app.GlobalActivityMonitor
import com.urbanairship.featureflag.FeatureFlagManager
import com.urbanairship.messagecenter.MessageCenter
import com.urbanairship.permission.Permission
import com.urbanairship.preferencecenter.PreferenceCenter
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeoutOrNull
import java.time.Instant

/**
 * Module's autopilot to customize Urban Airship.
 */
public abstract class BaseAutopilot : Autopilot() {

    private var extenderProvider: ExtenderProvider = ExtenderProvider()
    private var configOptions: AirshipConfigOptions? = null
    private var firstReady: Boolean = false
    private var rejectedConfig: ProxyConfig? = null
    private var hasRejectedConfig: Boolean = false

    private val dispatcher = CoroutineScope(Dispatchers.Default + SupervisorJob())

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

        val activityMonitor = GlobalActivityMonitor.shared(context.applicationContext)
        if (activityMonitor.isAppForegrounded) {
            LaunchDeepLinkTracker.shared().markLaunchResolved()
        } else {
            activityMonitor.addApplicationListener(object : ApplicationListener {
                override fun onForeground(timestamp: Instant) {
                    LaunchDeepLinkTracker.shared().markLaunchResolved()
                    activityMonitor.removeApplicationListener(this)
                }

                override fun onBackground(timestamp: Instant) {}
            })
        }

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

        dispatcher.launch {
            FeatureFlagManager.shared().statusUpdates
                .distinctUntilChanged()
                .collect {
                    EventEmitter.shared().addEvent(
                        FeatureFlagStatusChangedEvent(it.toProxyString()),
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
                val shouldDisplay = AirshipPluginExtensions.onShouldDisplayForegroundNotification

                // runBlocking holds the push-handling thread, so a stalled override falls back
                // to the default instead of delaying the notification.
                val override = if (shouldDisplay == null) {
                    AirshipPluginOverride.UseDefault
                } else {
                    withTimeoutOrNull(FOREGROUND_DISPLAY_OVERRIDE_TIMEOUT_MS) {
                        shouldDisplay(message)
                    } ?: run {
                        UALog.w { "Foreground notification override timed out, using the default" }
                        AirshipPluginOverride.UseDefault
                    }
                }
                return@runBlocking when (override) {
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
        val proxyStore = AirshipProxy.shared(context).proxyStore

        if (!firstReady) {
            onMigrateData(context, proxyStore)
            firstReady = true
        }

        val proxyConfig = proxyStore.airshipConfig
        val extender = extenderProvider.get(context)

        // Core asks again at every entry point until takeoff succeeds, so a config that already
        // failed validation is rejected without rebuilding it, unless an extender may change it.
        if (extender == null && hasRejectedConfig && proxyConfig == rejectedConfig) {
            UALog.v { "Airship config unchanged since it failed validation, skipping rebuild" }
            return false
        }

        var builder = createConfigBuilder(context)
        proxyConfig?.let {
            UALog.v { "Applying proxy config to Airship config" }
            builder.applyProxyConfig(context, it)
        }

        builder = extender?.extendConfig(context, builder) ?: builder

        val configOptions = builder.build()

        return try {
            configOptions.validate()
            this.configOptions = configOptions
            rejectedConfig = null
            hasRejectedConfig = false
            UALog.i { "Airship config validated successfully" }
            true
        } catch (e: Exception) {
            rejectedConfig = proxyConfig
            hasRejectedConfig = true
            UALog.w { "Airship config validation failed: ${e.message}" }
            false
        }
    }

    /**
     * Creates the config builder used to take off.
     *
     * This is called again only when the stored proxy config changes or a plugin extender is
     * installed, so an override must not depend on state that changes while the app runs.
     *
     * @param context The application context.
     * @return The config builder.
     */
    public open fun createConfigBuilder(context: Context): AirshipConfigOptions.Builder =
        AirshipConfigOptions.newBuilder()
            .let {
                try {
                    it.tryApplyDefaultProperties(context)
                } catch (e: Exception) {
                    UALog.v { "Failed to load config from properties file: ${e.message}" }
                }
                it
            }
            .setRequireInitialRemoteConfigEnabled(true)

    override fun createAirshipConfigOptions(context: Context): AirshipConfigOptions? = configOptions

    public abstract fun onMigrateData(context: Context, proxyStore: ProxyStore)

    private companion object {
        const val FOREGROUND_DISPLAY_OVERRIDE_TIMEOUT_MS = 3000L
    }
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
    proxyConfig.urlAllowListScopeJavaScriptInterface?.let {
        this.setUrlAllowListScopeJavaScriptInterface(it.toTypedArray())
    }
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

    // isReady runs on the main thread while Airship's onReady callback runs on a background one,
    // so the cached instance has to be published across threads.
    @Synchronized
    fun get(context: Context): AirshipPluginExtender? {
        if (!created) {
            extender = createExtender(context)
            created = true
        }
        return extender
    }

    @Synchronized
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
