package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.PendingResult
import com.urbanairship.channel.AirshipChannel
import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonValue

public class ChannelProxy(private val channelProvider: () -> AirshipChannel) {
    public fun enableChannelCreation() {
        channelProvider().enableChannelCreation()
    }

    public fun getChannelId(): String? {
        return channelProvider().id
    }

    public fun addTag(tag: String) {
        channelProvider().editTags().addTag(tag).apply()
    }

    public fun removeTag(tag: String) {
        channelProvider().editTags().removeTag(tag).apply()
    }

    public fun getTags() {
        channelProvider().tags
    }

    public fun getSubscriptionLists(): PendingResult<Set<String>> {
        return channelProvider().getSubscriptionLists(true)
    }

    public fun editSubscriptionLists(operations: JsonValue) {
        val parsedOperations = operations.requireList().map {
            SubscriptionListOperation(it.requireMap())
        }

        editSubscriptionLists(parsedOperations)
    }

    public fun editSubscriptionLists(operations: List<SubscriptionListOperation>) {
        val editor = channelProvider().editSubscriptionLists()
        operations.forEach { operation ->
            when (operation.action) {
                SubscriptionOperationAction.SUBSCRIBE -> editor.subscribe(operation.listId)
                SubscriptionOperationAction.UNSUBSCRIBE -> editor.unsubscribe(operation.listId)
            }
        }
        editor.apply()
    }

    public enum class SubscriptionOperationAction {
        SUBSCRIBE, UNSUBSCRIBE
    }

    public data class SubscriptionListOperation(
        public val listId: String,
        public val action: SubscriptionOperationAction
    ) {
        internal constructor(json: JsonMap) : this(
            listId = json.require("listId").requireString(),
            action = SubscriptionOperationAction.valueOf(
                json.require("action").requireString().uppercase()
            )
        )
    }


//    /**
//     * Edits the channel tag groups.
//     * Operations should each be a map with the following:
//     * - operationType: Either add or remove
//     * - group: The group to modify
//     * - tags: The tags to add or remove.
//     *
//     * @param operations An array of operations.
//     */
//    fun editChannelTagGroups(operations: ReadableArray) {
//        if (!Utils.ensureAirshipReady()) {
//            return
//        }
//        applyTagGroupOperations(UAirship.shared().channel.editTagGroups(), operations)
//    }
//


//    /**
//     * Edits the channel attributes.
//     * Operations should each be a map with the following:
//     * - action: Either set or remove
//     * - value: The group to modify
//     * - key: The tags to add or remove.
//     *
//     * @param operations An array of operations.
//     */
//    fun editChannelAttributes(operations: ReadableArray) {
//        if (!Utils.ensureAirshipReady()) {
//            return
//        }
//        applyAttributeOperations(UAirship.shared().channel.editAttributes(), operations)
//    }


//    /**
//     * Edit subscription lists associated with the current Channel.
//     *
//     *
//     * List updates should each be a map with the following:
//     * - type: Either subscribe or unsubscribe.
//     * - listId: ID of the subscription list to subscribe to or unsubscribe from.
//     *
//     * @param subscriptionListUpdates The subscription lists.
//     */
//    fun editChannelSubscriptionLists(subscriptionListUpdates: ReadableArray) {
//        if (!Utils.ensureAirshipReady()) {
//            return
//        }
//        val editor = UAirship.shared().channel.editSubscriptionLists()
//        for (i in 0 until subscriptionListUpdates.size()) {
//            val subscriptionListUpdate = subscriptionListUpdates.getMap(i)
//            val listId = subscriptionListUpdate.getString(SUBSCRIBE_LIST_OPERATION_LISTID)
//            val type = subscriptionListUpdate.getString(SUBSCRIBE_LIST_OPERATION_TYPE)
//            if (listId == null || type == null) {
//                continue
//            }
//            if ("subscribe" == type) {
//                editor.subscribe(listId)
//            } else if ("unsubscribe" == type) {
//                editor.unsubscribe(listId)
//            }
//        }
//        editor.apply()
//    }


}