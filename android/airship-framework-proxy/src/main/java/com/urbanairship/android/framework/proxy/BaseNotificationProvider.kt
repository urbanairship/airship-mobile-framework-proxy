/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Context
import androidx.annotation.ColorInt
import androidx.annotation.DrawableRes
import androidx.core.app.NotificationCompat
import com.urbanairship.AirshipConfigOptions
import com.urbanairship.push.notifications.AirshipNotificationProvider
import com.urbanairship.push.notifications.NotificationArguments

public open class BaseNotificationProvider(
    internal val context: Context,
    configOptions: AirshipConfigOptions
) : AirshipNotificationProvider(context, configOptions) {

    private val preferences: ProxyStore by lazy {
        ProxyStore.shared(context)
    }

    private val notificationConfig: NotificationConfig?
        get() {
            return preferences.notificationConfig
                ?: preferences.airshipConfig?.androidConfig?.notificationConfig
        }

    override fun getDefaultNotificationChannelId(): String {
        return notificationConfig?.defaultChannelId
            ?: super.getDefaultNotificationChannelId()
    }

    @DrawableRes
    override fun getSmallIcon(): Int {
        val iconResourceName: String? = notificationConfig?.icon
        iconResourceName?.let {
            val id = Utils.getNamedResource(context, it, "drawable")
            if (id > 0) {
                return id
            }
        }

        return super.getSmallIcon()
    }

    @DrawableRes
    override fun getLargeIcon(): Int {
        val largeIconResourceName: String? = notificationConfig?.largeIcon

        largeIconResourceName?.let {
            val id = Utils.getNamedResource(context, it, "drawable")
            if (id > 0) {
                return id
            }
        }
        return super.getLargeIcon()
    }

    @ColorInt
    override fun getDefaultAccentColor(): Int {
        val accentHexColor: String? = notificationConfig?.accentColor

        return if (accentHexColor != null) {
            Utils.getHexColor(accentHexColor, super.getDefaultAccentColor())
        } else {
            super.getDefaultAccentColor()
        }
    }

    override fun onExtendBuilder(
        context: Context,
        builder: NotificationCompat.Builder,
        arguments: NotificationArguments
    ): NotificationCompat.Builder {
        builder.extras.putBundle(PUSH_MESSAGE_BUNDLE_EXTRA, arguments.message.pushBundle)
        return super.onExtendBuilder(context, builder, arguments)
    }

    internal companion object {
        internal const val PUSH_MESSAGE_BUNDLE_EXTRA: String = "com.urbanairship.push_bundle";
    }
}
