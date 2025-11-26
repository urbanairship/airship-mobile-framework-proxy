package com.urbanairship.android.framework.proxy.proxies

import android.content.Intent
import android.net.Uri
import com.urbanairship.Airship
import com.urbanairship.android.framework.proxy.MessageCenterMessage
import com.urbanairship.android.framework.proxy.ProxyLogger
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

    public fun showMessageView(messageId: String) {
        launchMessageCenterIntent(MessageCenter.VIEW_MESSAGE_INTENT_ACTION, messageId)
    }

    public fun showMessageCenter(messageId: String?) {
        launchMessageCenterIntent(MessageCenter.VIEW_MESSAGE_CENTER_INTENT_ACTION, messageId)
    }

    private fun launchMessageCenterIntent(intentAction: String, messageId: String?) {
        MainScope().launch {
            _displayState.emit(true)
            messageCenterProvider()

            val context = Airship.application
            val intent = Intent(intentAction)
                .setPackage(context.packageName)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

            messageId?.let {
                intent.setData(Uri.fromParts("message", it, null as String?))
            }

            try {
                context.startActivity(intent)
            } catch(exception: Exception) {
                ProxyLogger.error(exception)
            }
        }
    }

    public fun dismiss() {
        MainScope().launch {
            _displayState.emit(false)
        }
    }

    public suspend fun getMessages(): List<MessageCenterMessage> {
        return messageCenterProvider().inbox.getMessages().map { MessageCenterMessage(it) }
    }

    public suspend fun getMessage(messageId: String): MessageCenterMessage {
        return MessageCenterMessage(
            requireNotNull(messageCenterProvider().inbox.getMessage(messageId))
        )
    }

    public fun deleteMessage(messageId: String) {
        messageCenterProvider().inbox.deleteMessages(messageId)
    }


    public fun markMessageRead(messageId: String) {
        messageCenterProvider().inbox.markMessagesRead(messageId)
    }

    public suspend fun refreshInbox(): Boolean {
        return messageCenterProvider().inbox.fetchMessages()
    }

    public suspend fun getUnreadMessagesCount(): Int {
        return messageCenterProvider().inbox.getUnreadCount()
    }

    public fun setAutoLaunchDefaultMessageCenter(enabled: Boolean) {
        proxyStore.isAutoLaunchMessageCenterEnabled = enabled
    }

}
