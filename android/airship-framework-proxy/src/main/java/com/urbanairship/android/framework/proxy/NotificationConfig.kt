package com.urbanairship.android.framework.proxy

import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue
import com.urbanairship.json.jsonMapOf

public data class NotificationConfig(
    val icon: String?,
    val largeIcon: String?,
    val accentColor: String?,
    val defaultChannelId: String?
) : JsonSerializable {

    internal constructor(config: JsonMap) : this(
        icon = config["icon"]?.string,
        largeIcon = config["largeIcon"]?.string,
        accentColor = config["accentColor"]?.string,
        defaultChannelId = config["defaultChannelId"]?.string,
    )

    override fun toJsonValue(): JsonValue =
        jsonMapOf(
            "icon" to icon,
            "largeIcon" to largeIcon,
            "accentColor" to accentColor,
            "defaultChannelId" to defaultChannelId
        ).toJsonValue()
}
