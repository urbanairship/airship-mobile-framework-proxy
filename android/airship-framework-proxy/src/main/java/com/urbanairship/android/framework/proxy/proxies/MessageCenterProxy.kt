package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.PendingResult
import com.urbanairship.android.framework.proxy.MessageCenterMessage
import com.urbanairship.android.framework.proxy.ProxyStore
import com.urbanairship.messagecenter.MessageCenter
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

public class MessageCenterProxy internal constructor(
    private val proxyStore: ProxyStore,
    private val messageCenterProvider: () -> MessageCenter
) {

    private val _displayState = MutableStateFlow(true)
    internal val displayState: StateFlow<Boolean> = _displayState

    public fun display(messageId: String?) {
        MainScope().launch {
            _displayState.emit(true)
            if (messageId != null) {
                messageCenterProvider().showMessageCenter(messageId)
            } else {
                messageCenterProvider().showMessageCenter()
            }
        }
    }

    public fun dismiss() {
        MainScope().launch {
            _displayState.emit(false)
        }
    }

    public fun getMessages(): List<MessageCenterMessage> {
        return messageCenterProvider().inbox.messages.map { MessageCenterMessage(it) }
    }

    public fun getMessage(messageId: String): MessageCenterMessage {
        return MessageCenterMessage(
            requireNotNull(messageCenterProvider().inbox.getMessage(messageId))
        )
    }

    public fun deleteMessage(messageId: String) {
        requireNotNull(messageCenterProvider().inbox.getMessage(messageId))
            .delete()
    }

    public fun markMessageRead(messageId: String) {
        requireNotNull(messageCenterProvider().inbox.getMessage(messageId))
            .markRead()
    }

    public fun refreshInbox(): PendingResult<Boolean> {
        val pendingResult = PendingResult<Boolean>()
        messageCenterProvider().inbox.fetchMessages {
            pendingResult.result = it
        }
        return pendingResult
    }

    public fun getUnreadMessagesCount(): Int {
        return messageCenterProvider().inbox.unreadCount
    }

    public fun setAutoLaunchDefaultMessageCenter(enabled: Boolean) {
        proxyStore.isAutoLaunchMessageCenterEnabled = enabled
    }

}
