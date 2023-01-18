package com.urbanairship.android.framework.proxy

import androidx.core.content.PermissionChecker.PermissionResult
import com.urbanairship.actions.DeepLinkListener
import com.urbanairship.android.framework.proxy.events.*
import com.urbanairship.channel.AirshipChannelListener
import com.urbanairship.messagecenter.InboxListener
import com.urbanairship.messagecenter.MessageCenter
import com.urbanairship.permission.OnPermissionStatusChangedListener
import com.urbanairship.preferencecenter.PreferenceCenter
import com.urbanairship.push.*

// TODO notificaiton status

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
    InboxListener {

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
            eventEmitter.addEvent(PushReceivedEvent(message))
        }
    }

    override fun onPushTokenUpdated(token: String) {
        eventEmitter.addEvent(PushTokenReceivedEvent(token))
    }

    override fun onNotificationPosted(notificationInfo: NotificationInfo) {
        eventEmitter.addEvent(PushReceivedEvent(notificationInfo))
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

    override fun onChannelUpdated(channelId: String) {
    }

    override fun onInboxUpdated() {
        eventEmitter.addEvent(
            MessageCenterUpdatedEvent(MessageCenter.shared().inbox.unreadCount, MessageCenter.shared().inbox.count)
        )
    }
}