/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Context
import androidx.annotation.ColorInt
import androidx.core.app.NotificationCompat
import com.urbanairship.AirshipConfigOptions
import com.urbanairship.push.notifications.AirshipNotificationProvider
import com.urbanairship.push.notifications.NotificationArguments
import com.urbanairship.push.notifications.NotificationProvider

public open class BaseNotificationProvider(
    internal val context: Context,
    internal val configOptions: AirshipConfigOptions
) : AirshipNotificationProvider(context, configOptions) {

    internal fun applyNotificationConfig(
        notificationConfig: NotificationConfig?
    ) {
        this.defaultNotificationChannelId = resolveNotificationChannel(notificationConfig)
        this.smallIcon = resolveSmallIcon(notificationConfig)
        this.largeIcon = resolveLargeIcon(notificationConfig)
        this.defaultAccentColor = resolveAccentColor(notificationConfig)
    }

    override fun onExtendBuilder(
        context: Context,
        builder: NotificationCompat.Builder,
        arguments: NotificationArguments
    ): NotificationCompat.Builder {
        builder.extras.putBundle(PUSH_MESSAGE_BUNDLE_EXTRA, arguments.message.getPushBundle())
        return super.onExtendBuilder(context, builder, arguments)
    }

    internal companion object {
        internal const val PUSH_MESSAGE_BUNDLE_EXTRA: String = "com.urbanairship.push_bundle";
    }


    private fun resolveNotificationChannel(notificationConfig: NotificationConfig?): String {
        // NotificationConfig
        val notificationConfigChannelId = notificationConfig?.defaultChannelId
        if (!notificationConfigChannelId.isNullOrEmpty()) {
            return notificationConfigChannelId
        }
        return configOptions.notificationChannel ?: NotificationProvider.DEFAULT_NOTIFICATION_CHANNEL
    }

    private fun resolveSmallIcon(notificationConfig: NotificationConfig?): Int {
        // NotificationConfig
        val notificationConfigIcon = findDrawable(notificationConfig?.icon)
        if (notificationConfigIcon != null) {
            return notificationConfigIcon
        }

        // AirshipConfig
        if (configOptions.notificationIcon != 0) {
            return configOptions.notificationIcon
        }

        // App icon
        val appIcon = context.applicationInfo.icon
        if (appIcon != 0) {
            return appIcon
        }

        // Default
        return findDrawable(DEFAULT_AIRSHIP_NOTIFICATION_ICON) ?: 0
    }

    @ColorInt
    private fun resolveAccentColor(notificationConfig: NotificationConfig?): Int {
        val accentHexColor: String? = notificationConfig?.accentColor
        val defaultAccentColor = configOptions.notificationAccentColor
        return if (accentHexColor != null) {
            Utils.getHexColor(accentHexColor, defaultAccentColor)
        } else {
            defaultAccentColor
        }
    }

    private fun resolveLargeIcon(notificationConfig: NotificationConfig?): Int {
        // NotificationConfig
        val notificationConfigIcon = findDrawable(notificationConfig?.largeIcon)
        if (notificationConfigIcon != null) {
            return notificationConfigIcon
        }

        // AirshipConfig
       return configOptions.notificationLargeIcon
    }

    private fun findDrawable(name: String?): Int? {
        if (name.isNullOrEmpty()) {
            return null
        }

        val id = Utils.getNamedResource(context, name, "drawable")
        return if (id > 0) {
            id
        } else {
            null
        }
    }

}
