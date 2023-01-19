/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Context
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
    private lateinit var proxyStore: ProxyStore

    override fun onAirshipReady(airship: UAirship) {
        super.onAirshipReady(airship)

        ProxyLogger.setLogLevel(airship.airshipConfigOptions.logLevel)
        val context = UAirship.getApplicationContext()

        val airshipListener = AirshipListener(proxyStore, EventEmitter.shared())

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

        configOptions = ConfigLoader().loadConfig(context)

        return try {
            configOptions!!.validate()
            true
        } catch (e: Exception) {
            false
        }
    }

    override fun createAirshipConfigOptions(context: Context): AirshipConfigOptions? {
        return configOptions
    }

    public abstract fun onMigrateData(context: Context, proxyStore: ProxyStore)
}