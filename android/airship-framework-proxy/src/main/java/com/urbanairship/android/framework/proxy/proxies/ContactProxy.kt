package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.android.framework.proxy.AttributeOperation
import com.urbanairship.UALog
import com.urbanairship.android.framework.proxy.ScopedSubscriptionListOperation
import com.urbanairship.android.framework.proxy.TagGroupOperation
import com.urbanairship.android.framework.proxy.applyOperation
import com.urbanairship.contacts.Contact
import com.urbanairship.json.JsonValue

public class ContactProxy internal constructor(private val contactProvider: () -> Contact) {
    public fun identify(namedUser: String?) {
        UALog.v { "identify called, namedUser=$namedUser" }
        if (namedUser.isNullOrBlank()) {
            contactProvider().reset()
        } else {
            contactProvider().identify(namedUser)
        }
    }

    public fun reset() {
        UALog.v { "reset called" }
        contactProvider().reset()
    }

    public fun getNamedUserId(): String? {
        UALog.v { "getNamedUserId called" }
        return contactProvider().namedUserId
    }

    public suspend fun getSubscriptionLists(): Map<String, List<String>> {
        UALog.v { "getSubscriptionLists called" }
        return contactProvider().fetchSubscriptionLists().getOrThrow().mapValues { entry ->
            entry.value.map { it.toString() }
        }
    }

    public fun notifyRemoteLogin() {
        UALog.v { "notifyRemoteLogin called" }
        contactProvider().notifyRemoteLogin()
    }

    public fun editSubscriptionLists(operations: JsonValue) {
        UALog.v { "editSubscriptionLists called with JsonValue, operations=$operations" }
        val parsedOperations = operations.requireList().map {
            ScopedSubscriptionListOperation(it.requireMap())
        }
        editSubscriptionLists(parsedOperations)
    }

    public fun editSubscriptionLists(operations: List<ScopedSubscriptionListOperation>) {
        UALog.v { "editSubscriptionLists called with ${operations.size} operations" }
        val editor = contactProvider().editSubscriptionLists()
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
        val editor = contactProvider().editTagGroups()
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
        val editor = contactProvider().editAttributes()
        operations.forEach { operation ->
            operation.applyOperation(editor)
        }
        editor.apply()
    }
}
