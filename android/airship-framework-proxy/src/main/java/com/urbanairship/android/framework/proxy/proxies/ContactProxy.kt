package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.android.framework.proxy.AttributeOperation
import com.urbanairship.UALog
import com.urbanairship.android.framework.proxy.ScopedSubscriptionListOperation
import com.urbanairship.android.framework.proxy.TagGroupOperation
import com.urbanairship.android.framework.proxy.applyOperation
import com.urbanairship.contacts.Contact
import com.urbanairship.contacts.EmailRegistrationOptions
import com.urbanairship.contacts.SmsRegistrationOptions
import com.urbanairship.json.JsonValue
import java.util.Date

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

    public fun registerEmail(address: String, options: EmailRegistrationOptions) {
        UALog.v { "registerEmail called, address=$address" }
        contactProvider().registerEmail(address, options)
    }

    public fun registerEmail(address: String, options: JsonValue) {
        UALog.v { "registerEmail called with JsonValue, address=$address" }
        registerEmail(address, parseEmailRegistrationOptions(options))
    }

    public fun registerSms(msisdn: String, options: SmsRegistrationOptions) {
        UALog.v { "registerSms called, msisdn=$msisdn" }
        contactProvider().registerSms(msisdn, options)
    }

    public fun registerSms(msisdn: String, options: JsonValue) {
        UALog.v { "registerSms called with JsonValue, msisdn=$msisdn" }
        registerSms(msisdn, parseSmsRegistrationOptions(options))
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

    private companion object {
        private const val TRANSACTIONAL_OPTED_IN_KEY = "transactional_opted_in"
        private const val COMMERCIAL_OPTED_IN_KEY = "commercial_opted_in"
        private const val PROPERTIES_KEY = "properties"
        private const val DOUBLE_OPT_IN_KEY = "double_opt_in"
        private const val SMS_SENDER_ID_KEY = "sender_id"

        private fun parseEmailRegistrationOptions(value: JsonValue): EmailRegistrationOptions {
            val map = value.optMap()
            val commercialMs = map.opt(COMMERCIAL_OPTED_IN_KEY).getLong(-1)
            val transactionalMs = map.opt(TRANSACTIONAL_OPTED_IN_KEY).getLong(-1)
            val properties = map.opt(PROPERTIES_KEY).map
            val doubleOptIn = map.opt(DOUBLE_OPT_IN_KEY).getBoolean(false)
            val commercialDate = if (commercialMs != -1L) Date(commercialMs) else null
            val transactionalDate = if (transactionalMs != -1L) Date(transactionalMs) else null
            return when {
                doubleOptIn ->
                    EmailRegistrationOptions.options(transactionalDate, properties, true)
                commercialMs != -1L ->
                    EmailRegistrationOptions.commercialOptions(
                        commercialDate,
                        transactionalDate,
                        properties
                    )
                else ->
                    EmailRegistrationOptions.options(transactionalDate, properties, false)
            }
        }

        private fun parseSmsRegistrationOptions(value: JsonValue): SmsRegistrationOptions {
            val senderId = value.optMap().opt(SMS_SENDER_ID_KEY).requireString()
            return SmsRegistrationOptions.options(senderId)
        }
    }
}
