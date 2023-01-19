package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.PendingResult
import com.urbanairship.android.framework.proxy.*
import com.urbanairship.android.framework.proxy.applyOperation
import com.urbanairship.contacts.Contact
import com.urbanairship.json.JsonValue

public class ContactProxy internal constructor(private val contactProvider: () -> Contact) {
    public fun setNamedUser(namedUser: String?) {
        if (namedUser.isNullOrBlank()) {
            contactProvider().reset()
        } else {
            contactProvider().identify(namedUser)
        }
    }

    public fun getNamedUser(): String? {
        return contactProvider().namedUserId
    }

    public fun getSubscriptionLists(): PendingResult<Map<String, List<String>>> {
        val pendingResult = PendingResult<Map<String, List<String>>>()
        contactProvider().subscriptionLists.addResultCallback { result ->
            pendingResult.result = result?.mapValues { entry ->
                entry.value.map { it.toString() }
            }
        }
        return pendingResult
    }

    public fun editSubscriptionLists(operations: JsonValue) {
        val parsedOperations = operations.requireList().map {
            ScopedSubscriptionListOperation(it.requireMap())
        }
        editSubscriptionLists(parsedOperations)
    }

    public fun editSubscriptionLists(operations: List<ScopedSubscriptionListOperation>) {
        val editor = contactProvider().editSubscriptionLists()
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
        val editor = contactProvider().editTagGroups()
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
        val editor = contactProvider().editAttributes()
        operations.forEach { operation ->
            operation.applyOperation(editor)
        }
        editor.apply()
    }
}