package com.urbanairship.android.framework.proxy

import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue
import com.urbanairship.messagecenter.Message

public data class MessageCenterMessage(
    val title: String,
    val id: String,
    val sentDate: Long,
    val listIconUrl: String?,
    val isRead: Boolean,
    val extras: Map<String, String?>,
    val expirationDate: Long?
) : JsonSerializable {

    internal constructor(message: Message) : this(
        title = message.title,
        id = message.id,
        sentDate = message.sentDate.time,
        listIconUrl = message.listIconUrl,
        isRead = message.isRead,
        extras = message.extras ?: emptyMap<String, String?>(),
        expirationDate = message.expirationDate?.time
    )

    override fun toJsonValue(): JsonValue = JsonMap.newBuilder()
        .put("title", title)
        .put("id", id)
        .put("sentDate", sentDate)
        .put("listIconUrl", listIconUrl)
        .put("isRead", isRead)
        .putOpt("extras", extras)
        .putOpt("expirationDate", expirationDate)
        .build()
        .toJsonValue()
}
