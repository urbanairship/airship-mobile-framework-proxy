/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.embedded.AirshipEmbeddedInfo
import com.urbanairship.json.JsonMap
import com.urbanairship.json.jsonMapOf

internal class PendingEmbeddedUpdated(pending: List<AirshipEmbeddedInfo>) : Event {
    override val type = EventType.PENDING_EMBEDDED_UPDATED

    override val body: JsonMap = jsonMapOf(
        "pending" to pending.map { jsonMapOf( "embeddedId" to it.embeddedId ) }
    )
}
