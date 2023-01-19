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

    public fun deleteMessage(messageId: String): Boolean {
        val message = messageCenterProvider().inbox.getMessage(messageId)
        message?.delete()
        return message != null
    }

    public fun markMessageRead(messageId: String): Boolean {
        val message = messageCenterProvider().inbox.getMessage(messageId)
        message?.markRead()
        return message != null
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