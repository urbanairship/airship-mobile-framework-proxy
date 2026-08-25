/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.json.JsonMap
import com.urbanairship.json.jsonMapOf

/**
 * Feature flag status event.
 *
 * @param status The status.
 */
internal class FeatureFlagStatusChangedEvent(status: String) : Event {
    override val type = EventType.FEATURE_FLAG_STATUS_CHANGED
    override val body: JsonMap = jsonMapOf(
        "status" to status
    )
}
