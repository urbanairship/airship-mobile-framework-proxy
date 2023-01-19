package com.urbanairship.android.framework.proxy.proxies

public class MessageCenterProxy {

//    /**
//     * Displays the default message center.
//     */
//    fun displayMessageCenter() {
//        if (!Utils.ensureAirshipReady()) {
//            return
//        }
//        MessageCenter.shared().showMessageCenter()
//    }
//
//    /**
//     * Dismisses the default message center.
//     */
//    fun dismissMessageCenter() {
//        if (!Utils.ensureAirshipReady()) {
//            return
//        } currentActivity ?. let {
//            val intent = Intent(it, CustomMessageCenterActivity::class.java)
//                .setAction(CLOSE_MESSAGE_CENTER)
//            it.startActivity(intent)
//        }
//    }
//
//    /**
//     * Display an inbox message in the default message center.
//     *
//     * @param messageId The id of the message to be displayed.
//     * @param promise   The JS promise.
//     */
//    fun displayMessage(messageId: String?, promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        MessageCenter.shared().showMessageCenter(messageId)
//        promise.resolve(true)
//    }
//
//    /**
//     * Dismisses the currently displayed inbox message.
//     */
//    fun dismissMessage() {
//        if (!Utils.ensureAirshipReady()) {
//            return
//        } currentActivity ?. let {
//            val intent = Intent(it, CustomMessageActivity::class.java)
//                .setAction(CLOSE_MESSAGE_CENTER)
//                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
//            it.startActivity(intent)
//        }
//    }
//


//
//    /**
//     * Retrieves the current inbox messages.
//     *
//     * @param promise The JS promise.
//     */
//    fun getInboxMessages(promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        val messagesArray = Arguments.createArray()
//        for (message in MessageCenter.shared().inbox.messages) {
//            val messageMap: WritableMap = WritableNativeMap()
//            messageMap.putString("title", message.title)
//            messageMap.putString("id", message.messageId)
//            messageMap.putDouble("sentDate", message.sentDate.time.toDouble())
//            messageMap.putString("listIconUrl", message.listIconUrl)
//            messageMap.putBoolean("isRead", message.isRead)
//            messageMap.putBoolean("isDeleted", message.isDeleted)
//            val extrasMap: WritableMap = WritableNativeMap()
//            val extras = message.extras
//            for (key in extras.keySet()) {
//                val value = extras[key].toString()
//                extrasMap.putString(key, value)
//            }
//            messageMap.putMap("extras", extrasMap)
//            messagesArray.pushMap(messageMap)
//        }
//        promise.resolve(messagesArray)
//    }
//
//    /**
//     * Deletes an inbox message.
//     *
//     * @param messageId The id of the message to be deleted.
//     * @param promise   The JS promise.
//     */
//    fun deleteInboxMessage(messageId: String?, promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        val message = MessageCenter.shared().inbox.getMessage(messageId)
//        if (message == null) {
//            promise.reject("STATUS_MESSAGE_NOT_FOUND", "Message not found")
//        } else {
//            message.delete()
//            promise.resolve(true)
//        }
//    }
//
//    /**
//     * Marks an inbox message as read.
//     *
//     * @param messageId The id of the message to be marked as read.
//     * @param promise   The JS promise.
//     */
//    fun markInboxMessageRead(messageId: String?, promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        val message = MessageCenter.shared().inbox.getMessage(messageId)
//        if (message == null) {
//            promise.reject("STATUS_MESSAGE_NOT_FOUND", "Message not found.")
//        } else {
//            message.markRead()
//            promise.resolve(true)
//        }
//    }
//
//
//
//    /**
//     * Forces the inbox to refresh. This is normally not needed as the inbox will automatically refresh on foreground or when a push arrives thats associated with a message.
//     *
//     * @param promise The JS promise.
//     */
//    fun refreshInbox(promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        MessageCenter.shared().inbox.fetchMessages { success ->
//            if (success) {
//                promise.resolve(true)
//            } else {
//                promise.reject("STATUS_DID_NOT_REFRESH", "Inbox failed to refresh")
//            }
//        }
//    }
//
//    /**
//     * Gets the count of Unread messages in the inbox.
//     *
//     * @param promise The JS promise.
//     */
//    fun getUnreadMessagesCount(promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        promise.resolve(MessageCenter.shared().inbox.unreadCount)
//    }
//
//    /**
//     * Sets the default behavior when the message center is launched from a push notification. If set to false the message center must be manually launched.
//     *
//     * @param enabled `true` to automatically launch the default message center, `false` to disable.
//     */
//    fun setAutoLaunchDefaultMessageCenter(enabled: Boolean) {
//        if (!Utils.ensureAirshipReady()) {
//            return
//        }
//        preferences.setAutoLaunchMessageCenter(enabled)
//    }
//
}