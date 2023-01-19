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
    public val context: Context,
    configOptions: AirshipConfigOptions
) : AirshipNotificationProvider(context, configOptions) {

    private val preferences: ProxyStore by lazy {
        ProxyStore.shared(context)
    }

    override fun getDefaultNotificationChannelId(): String {
        return preferences.notificationConfig?.defaultChannelId
            ?: super.getDefaultNotificationChannelId()
    }

    @DrawableRes
    override fun getSmallIcon(): Int {
        val iconResourceName: String? = preferences.notificationConfig?.icon

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
        val largeIconResourceName: String? = preferences.notificationConfig?.largeIcon

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
        val accentHexColor: String? = preferences.notificationConfig?.accentColor

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