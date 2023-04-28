package com.urbanairship.android.framework.proxy

import com.urbanairship.channel.AttributeEditor
import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonValue
import java.util.*

public enum class AttributeOperationAction {
    REMOVE, SET
}

public enum class AttributeValueType {
    STRING, NUMBER, DATE
}

public data class AttributeOperation(
    public val attribute: String,
    public val value: JsonValue?,
    public val valueType: AttributeValueType?,
    public val action: AttributeOperationAction
) {
    public constructor(json: JsonMap) : this(
        attribute = json.require("key").requireString(),
        value = json.get("value"),
        valueType = json.opt("type").string?.let {
            AttributeValueType.valueOf(it.uppercase())
        },
        action = AttributeOperationAction.valueOf(
            json.require("action").requireString().uppercase()
        )
    )
}

internal fun AttributeOperation.applyOperation(editor: AttributeEditor) {
    when (action) {
        AttributeOperationAction.REMOVE -> editor.removeAttribute(attribute)
        AttributeOperationAction.SET -> {
            when (requireNotNull(valueType)) {
                AttributeValueType.DATE -> editor.setAttribute(
                    attribute,
                    Date(requireNotNull(value).getLong(0))
                )
                AttributeValueType.STRING -> editor.setAttribute(
                    attribute,
                    Date(requireNotNull(value).requireString())
                )
                AttributeValueType.NUMBER -> editor.setAttribute(
                    attribute,
                    requireNotNull(value).getDouble(0.0)
                )
            }
        }
    }
}
