package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.UALog
import com.urbanairship.analytics.Analytics
import com.urbanairship.analytics.CustomEvent
import com.urbanairship.json.JsonValue

public class AnalyticsProxy internal constructor(private val analyticsProvider: () -> Analytics) {
    public fun associateIdentifier(key: String, value: String?) {
        UALog.v { "associateIdentifier called, key=$key, value=$value" }
        val editor = analyticsProvider().editAssociatedIdentifiers()
        if (value == null) {
            editor.removeIdentifier(key)
        } else {
            editor.addIdentifier(key, value)
        }
        editor.apply()
    }

    public fun trackScreen(screen: String?) {
        UALog.v { "trackScreen called, screen=$screen" }
        analyticsProvider().trackScreen(screen)
    }

    public fun addEvent(json: JsonValue) {
        UALog.v { "addEvent called, json=$json" }
        val jsonMap = json.optMap()

        val event = CustomEvent.newBuilder(jsonMap.require("eventName").requireString()).apply {
            val eventValue = jsonMap.opt("eventValue")
            if (eventValue.isNumber) {
                this.setEventValue(eventValue.getDouble(0.0))
            }

            jsonMap.opt("properties").map.let { this.setProperties(it) }
            jsonMap.opt("transactionId").string.let { this.setTransactionId(it) }

            val interactionId = jsonMap.opt("interactionId").string
            val interactionType = jsonMap.opt("interactionType").string
            if (interactionId != null && interactionType != null) {
                this.setInteraction(interactionType, interactionId)
            }
        }.build()

        if (event.isValid()) {
            analyticsProvider().addEvent(event)
        } else {
            throw java.lang.IllegalArgumentException("Invalid event $json")
        }
    }

    public fun getSessionId(): String {
        UALog.v { "getSessionId called" }
        return analyticsProvider().sessionId
    }
}
