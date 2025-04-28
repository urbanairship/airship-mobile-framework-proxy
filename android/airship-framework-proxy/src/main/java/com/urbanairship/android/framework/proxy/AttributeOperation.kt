package com.urbanairship.android.framework.proxy

import com.urbanairship.channel.AttributeEditor
import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonValue
import com.urbanairship.json.optionalField
import com.urbanairship.json.requireField
import java.util.*
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

public enum class AttributeOperationAction {
    REMOVE, SET
}

public enum class AttributeValueType {
    STRING, NUMBER, DATE, JSON
}

public data class AttributeOperation(
    public val attribute: String,
    public val value: JsonValue?,
    public val valueType: AttributeValueType?,
    public val action: AttributeOperationAction,
    public val instanceId: String? = null,
    public val expiry: Date? = null
) {
    public constructor(json: JsonMap) : this(
        attribute = json.requireField("key"),
        value = json.get("value"),
        valueType = json.optionalField<String>("type")?.let {
            AttributeValueType.valueOf(it.uppercase())
        },
        action = AttributeOperationAction.valueOf(
            json.requireField<String>("action").uppercase()
        ),
        instanceId = json.optionalField("instance_id"),
        expiry = json.optionalField<Long>("expiration_milliseconds")?.let {
            Date(it)
        }
    )
}

internal fun AttributeOperation.applyOperation(editor: AttributeEditor) {
    when (action) {
        AttributeOperationAction.REMOVE -> if (instanceId == null) {
            editor.removeAttribute(attribute)
        } else {
            editor.removeAttribute(attribute, instanceId)
        }
        AttributeOperationAction.SET -> {
            when (requireNotNull(valueType)) {
                AttributeValueType.DATE -> editor.setAttribute(
                    attribute,
                    Date(requireNotNull(value).getLong(0))
                )
                AttributeValueType.STRING -> editor.setAttribute(
                    attribute,
                    requireNotNull(value).requireString()
                )
                AttributeValueType.NUMBER -> editor.setAttribute(
                    attribute,
                    requireNotNull(value).getDouble(0.0)
                )
                AttributeValueType.JSON ->  editor.setAttribute(
                    attribute,
                    requireNotNull(instanceId),
                    expiry,
                    requireNotNull(value).requireMap(),
                )
            }
        }
    }
}
