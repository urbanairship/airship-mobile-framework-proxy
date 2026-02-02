package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.android.framework.proxy.AttributeOperation
import com.urbanairship.UALog
import com.urbanairship.android.framework.proxy.SubscriptionListOperation
import com.urbanairship.android.framework.proxy.TagGroupOperation
import com.urbanairship.android.framework.proxy.TagOperation
import com.urbanairship.android.framework.proxy.applyOperation
import com.urbanairship.channel.AirshipChannel
import com.urbanairship.json.JsonValue
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first

public class ChannelProxy internal constructor(private val channelProvider: () -> AirshipChannel) {
    public fun enableChannelCreation() {
        UALog.v { "enableChannelCreation called" }
        channelProvider().enableChannelCreation()
    }

    public fun getChannelId(): String? {
        UALog.v { "getChannelId called" }
        return channelProvider().id
    }

    public suspend fun waitForChannelId(): String {
        UALog.v { "waitForChannelId called" }
        return channelProvider().channelIdFlow.filterNotNull().first()
    }

    public fun addTag(tag: String) {
        UALog.v { "addTag called, tag=$tag" }
        channelProvider().editTags().addTag(tag).apply()
    }

    public fun removeTag(tag: String) {
        UALog.v { "removeTag called, tag=$tag" }
        channelProvider().editTags().removeTag(tag).apply()
    }

    public fun editTags(operations: JsonValue) {
        UALog.v { "editTags called with JsonValue, operations=$operations" }
        val parsedOperations = operations.requireList().map {
            TagOperation(it.requireMap())
        }
        editTags(parsedOperations)
    }

    public fun editTags(operations: List<TagOperation>) {
        UALog.v { "editTags called with ${operations.size} operations" }
        val editor = channelProvider().editTags()
        operations.forEach { operation ->
            operation.applyOperation(editor)
        }
        editor.apply()
    }

    public fun getTags(): Set<String> {
        UALog.v { "getTags called" }
        return channelProvider().tags
    }

    public suspend fun getSubscriptionLists(): Set<String> {
        UALog.v { "getSubscriptionLists called" }
        return channelProvider().fetchSubscriptionLists().getOrThrow()
    }

    public fun editSubscriptionLists(operations: JsonValue) {
        UALog.v { "editSubscriptionLists called with JsonValue, operations=$operations" }
        val parsedOperations = operations.requireList().map {
            SubscriptionListOperation(it.requireMap())
        }
        editSubscriptionLists(parsedOperations)
    }

    public fun editSubscriptionLists(operations: List<SubscriptionListOperation>) {
        UALog.v { "editSubscriptionLists called with ${operations.size} operations" }
        val editor = channelProvider().editSubscriptionLists()
        operations.forEach { operation ->
            operation.applyOperation(editor)
        }
        editor.apply()
    }

    public fun editTagGroups(operations: JsonValue) {
        UALog.v { "editTagGroups called with JsonValue, operations=$operations" }
        val parsedOperations = operations.requireList().map {
            TagGroupOperation(it.requireMap())
        }
        editTagGroups(parsedOperations)
    }

    public fun editTagGroups(operations: List<TagGroupOperation>) {
        UALog.v { "editTagGroups called with ${operations.size} operations" }
        val editor = channelProvider().editTagGroups()
        operations.forEach { operation ->
            operation.applyOperation(editor)
        }
        editor.apply()
    }

    public fun editAttributes(operations: JsonValue) {
        UALog.v { "editAttributes called with JsonValue, operations=$operations" }
        val parsedOperations = operations.requireList().map {
            AttributeOperation(it.requireMap())
        }
        editAttributes(parsedOperations)
    }

    public fun editAttributes(operations: List<AttributeOperation>) {
        UALog.v { "editAttributes called with ${operations.size} operations" }
        val editor = channelProvider().editAttributes()
        operations.forEach { operation ->
            operation.applyOperation(editor)
        }
        editor.apply()
    }
}
