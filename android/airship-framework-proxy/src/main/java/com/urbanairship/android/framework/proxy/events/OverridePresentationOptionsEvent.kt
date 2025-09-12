/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType
import com.urbanairship.json.JsonMap
import com.urbanairship.json.jsonMapOf

internal class OverridePresentationOptionsEvent: Event {
    override val type: EventType = EventType.OVERRIDE_FOREGROUND_PRESENTATION
    override val body: JsonMap

    constructor(body: JsonMap) {
        this.body = body
    }

    /**
     * Default constructor.
     *
     * @param pushPayload The push payload.
     * @param requestId The request ID.
     */
    constructor(pushPayload: Map<String, Any>, requestId: String) : this(
        jsonMapOf(
            "pushPayload" to pushPayload,
            "requestId" to requestId
        )
    )
}
