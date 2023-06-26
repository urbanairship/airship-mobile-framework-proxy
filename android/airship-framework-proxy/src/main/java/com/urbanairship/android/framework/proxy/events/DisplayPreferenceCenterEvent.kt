/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType
import com.urbanairship.json.JsonMap
import com.urbanairship.json.jsonMapOf

internal class DisplayPreferenceCenterEvent(preferenceCenterId: String) : Event {
    override val type = EventType.DISPLAY_PREFERENCE_CENTER
    override val body: JsonMap = jsonMapOf("preferenceCenterId" to preferenceCenterId)
}
