package com.urbanairship.android.framework.proxy

import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue


public data class NotificationConfig(
    val icon: String?,
    val largeIcon: String?,
    val accentColor: String?,
    val defaultChannelId: String?
) : JsonSerializable {

    internal constructor(config: JsonMap) : this(
        icon = config.get("icon")?.string,
        largeIcon = config.get("largeIcon")?.string,
        accentColor = config.get("accentColor")?.string,
        defaultChannelId = config.get("defaultChannelId")?.string,
    )

    override fun toJsonValue(): JsonValue =
        JsonMap.newBuilder()
            .putOpt("icon", icon)
            .putOpt("largeIcon", largeIcon)
            .putOpt("accentColor", accentColor)
            .putOpt("defaultChannelId", defaultChannelId)
            .build()
            .toJsonValue()
}