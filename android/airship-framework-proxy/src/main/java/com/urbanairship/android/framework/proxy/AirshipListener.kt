package com.urbanairship.android.framework.proxy

import com.urbanairship.UAirship
import com.urbanairship.actions.DeepLinkListener
import com.urbanairship.android.framework.proxy.events.ChannelCreatedEvent
import com.urbanairship.android.framework.proxy.events.DeepLinkEvent
import com.urbanairship.android.framework.proxy.events.DisplayMessageCenterEvent
import com.urbanairship.android.framework.proxy.events.DisplayPreferenceCenterEvent
import com.urbanairship.android.framework.proxy.events.EventEmitter
import com.urbanairship.android.framework.proxy.events.MessageCenterUpdatedEvent
import com.urbanairship.android.framework.proxy.events.NotificationResponseEvent
import com.urbanairship.android.framework.proxy.events.PushReceivedEvent
import com.urbanairship.android.framework.proxy.events.PushTokenReceivedEvent
import com.urbanairship.app.GlobalActivityMonitor
import com.urbanairship.channel.AirshipChannelListener
import com.urbanairship.messagecenter.InboxListener
import com.urbanairship.messagecenter.MessageCenter
import com.urbanairship.preferencecenter.PreferenceCenter
import com.urbanairship.push.NotificationActionButtonInfo
import com.urbanairship.push.NotificationInfo
import com.urbanairship.push.NotificationListener
import com.urbanairship.push.PushListener
import com.urbanairship.push.PushMessage
import com.urbanairship.push.PushTokenListener
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

internal class AirshipListener(
    private val proxyStore: ProxyStore,
    private val eventEmitter: EventEmitter
) :
    MessageCenter.OnShowMessageCenterListener,
    PreferenceCenter.OnOpenListener,
    PushListener,
    PushTokenListener,
    NotificationListener,
    DeepLinkListener,
    AirshipChannelListener,
    InboxListener
{
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val isAppForegrounded: Boolean
        get() {
            return GlobalActivityMonitor.shared(UAirship.getApplicationContext()).isAppForegrounded
        }

    private val forwardNotificationListener: NotificationListener?
        get() {
            return AirshipPluginExtensions.forwardNotificationListener ?: AirshipPluginForwardListeners.notificationListener
        }

    override fun onShowMessageCenter(messageId: String?): Boolean {
        return if (proxyStore.isAutoLaunchMessageCenterEnabled) {
            false
        } else {
            eventEmitter.addEvent(DisplayMessageCenterEvent(messageId))
            true
        }
    }

    override fun onOpenPreferenceCenter(preferenceCenterId: String): Boolean {
        return if (proxyStore.isAutoLaunchPreferenceCenterEnabled(preferenceCenterId)) {
            false
        } else {
            eventEmitter.addEvent(DisplayPreferenceCenterEvent(preferenceCenterId))
            true
        }
    }

    override fun onPushReceived(message: PushMessage, notificationPosted: Boolean) {
        if (!notificationPosted) {
            eventEmitter.addEvent(PushReceivedEvent(message, isAppForegrounded))
        }
    }

    override fun onPushTokenUpdated(token: String) {
        eventEmitter.addEvent(PushTokenReceivedEvent(token))
    }

    override fun onNotificationPosted(notificationInfo: NotificationInfo) {
        eventEmitter.addEvent(PushReceivedEvent(notificationInfo, isAppForegrounded))
        forwardNotificationListener?.onNotificationPosted(notificationInfo)
    }

    override fun onNotificationOpened(notificationInfo: NotificationInfo): Boolean {
        eventEmitter.addEvent(
            NotificationResponseEvent(notificationInfo, null)
        )

        return forwardNotificationListener?.onNotificationOpened(notificationInfo) ?: false
    }

    override fun onNotificationForegroundAction(
        notificationInfo: NotificationInfo,
        notificationActionButtonInfo: NotificationActionButtonInfo
    ): Boolean {
        eventEmitter.addEvent(
            NotificationResponseEvent(notificationInfo, notificationActionButtonInfo)
        )
        return forwardNotificationListener?.onNotificationForegroundAction(notificationInfo, notificationActionButtonInfo) ?: false
    }

    override fun onNotificationBackgroundAction(
        notificationInfo: NotificationInfo,
        notificationActionButtonInfo: NotificationActionButtonInfo
    ) {
        eventEmitter.addEvent(
            NotificationResponseEvent(notificationInfo, notificationActionButtonInfo)
        )
        forwardNotificationListener?.onNotificationBackgroundAction(notificationInfo, notificationActionButtonInfo)
    }

    override fun onNotificationDismissed(notificationInfo: NotificationInfo) {
        forwardNotificationListener?.onNotificationDismissed(notificationInfo)
    }

    override fun onDeepLink(deepLink: String): Boolean {
        val override = AirshipPluginExtensions.onDeepLink?.invoke(deepLink)
        if (override == null) {
            if (AirshipPluginForwardListeners.deepLinkListener?.onDeepLink(deepLink) == true) {
                ProxyLogger.debug("Deeplink handling for $deepLink overridden by deprecated forward delegate")
                return true
            }
        }

        when(override) {
            is AirshipPluginOverride.Override -> {
                ProxyLogger.debug("Deeplink handling for $deepLink overridden by plugin extension")
            }
            is AirshipPluginOverride.UseDefault, null -> {
                eventEmitter.addEvent(DeepLinkEvent(deepLink))
            }
        }
        return true
    }

    override fun onChannelCreated(channelId: String) {
        eventEmitter.addEvent(ChannelCreatedEvent(channelId))
    }

    override fun onInboxUpdated() {
        scope.launch {
            eventEmitter.addEvent(
                MessageCenterUpdatedEvent(
                    MessageCenter.shared().inbox.getUnreadCount(),
                    MessageCenter.shared().inbox.getCount()
                ),
                replacePending = true
            )
        }

    }

}
