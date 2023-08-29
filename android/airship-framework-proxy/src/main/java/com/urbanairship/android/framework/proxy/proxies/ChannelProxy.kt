package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.PendingResult
import com.urbanairship.android.framework.proxy.AttributeOperation
import com.urbanairship.android.framework.proxy.SubscriptionListOperation
import com.urbanairship.android.framework.proxy.TagGroupOperation
import com.urbanairship.android.framework.proxy.TagOperation
import com.urbanairship.android.framework.proxy.applyOperation
import com.urbanairship.channel.AirshipChannel
import com.urbanairship.json.JsonValue

public class ChannelProxy internal constructor(private val channelProvider: () -> AirshipChannel) {
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

    public fun editTags(operations: JsonValue) {
        val parsedOperations = operations.requireList().map {
            TagOperation(it.requireMap())
        }
        editTags(parsedOperations)
    }

    public fun editTags(operations: List<TagOperation>) {
        val editor = channelProvider().editTags()
        operations.forEach { operation ->
            operation.applyOperation(editor)
        }
        editor.apply()
    }

    public fun getTags(): Set<String> {
        return channelProvider().tags
    }

    public fun getSubscriptionLists(): PendingResult<Set<String>> {
        return channelProvider().fetchSubscriptionListsPendingResult()
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
            operation.applyOperation(editor)
        }
        editor.apply()
    }

    public fun editTagGroups(operations: JsonValue) {
        val parsedOperations = operations.requireList().map {
            TagGroupOperation(it.requireMap())
        }
        editTagGroups(parsedOperations)
    }

    public fun editTagGroups(operations: List<TagGroupOperation>) {
        val editor = channelProvider().editTagGroups()
        operations.forEach { operation ->
            operation.applyOperation(editor)
        }
        editor.apply()
    }

    public fun editAttributes(operations: JsonValue) {
        val parsedOperations = operations.requireList().map {
            AttributeOperation(it.requireMap())
        }
        editAttributes(parsedOperations)
    }

    public fun editAttributes(operations: List<AttributeOperation>) {
        val editor = channelProvider().editAttributes()
        operations.forEach { operation ->
            operation.applyOperation(editor)
        }
        editor.apply()
    }
}
