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
    private val isAppForegrounded: Boolean
        get() {
            return GlobalActivityMonitor.shared(UAirship.getApplicationContext()).isAppForegrounded
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
    }

    override fun onNotificationOpened(notificationInfo: NotificationInfo): Boolean {
        eventEmitter.addEvent(
            NotificationResponseEvent(notificationInfo, null)
        )
        return false
    }

    override fun onNotificationForegroundAction(
        notificationInfo: NotificationInfo,
        notificationActionButtonInfo: NotificationActionButtonInfo
    ): Boolean {
        eventEmitter.addEvent(
            NotificationResponseEvent(notificationInfo, notificationActionButtonInfo)
        )
        return false
    }

    override fun onNotificationBackgroundAction(
        notificationInfo: NotificationInfo,
        notificationActionButtonInfo: NotificationActionButtonInfo
    ) {
        eventEmitter.addEvent(
            NotificationResponseEvent(notificationInfo, notificationActionButtonInfo)
        )
    }

    override fun onNotificationDismissed(notificationInfo: NotificationInfo) {}

    override fun onDeepLink(deepLink: String): Boolean {
        eventEmitter.addEvent(DeepLinkEvent(deepLink))
        return true
    }

    override fun onChannelCreated(channelId: String) {
        eventEmitter.addEvent(ChannelCreatedEvent(channelId))
    }

    override fun onInboxUpdated() {
        eventEmitter.addEvent(
            MessageCenterUpdatedEvent(
                MessageCenter.shared().inbox.unreadCount,
                MessageCenter.shared().inbox.count
            ),
            replacePending = true
        )
    }

}
