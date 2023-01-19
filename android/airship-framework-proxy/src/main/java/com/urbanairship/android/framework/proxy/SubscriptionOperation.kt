package com.urbanairship.android.framework.proxy

import com.urbanairship.channel.SubscriptionListEditor
import com.urbanairship.json.JsonMap

public enum class SubscriptionListOperationAction {
    SUBSCRIBE, UNSUBSCRIBE
}

public data class SubscriptionListOperation(
    public val listId: String,
    public val action: SubscriptionListOperationAction
) {
    public constructor(json: JsonMap) : this(
        listId = json.require("listId").requireString(),
        action = SubscriptionListOperationAction.valueOf(
            json.require("action").requireString().uppercase()
        )
    )
}

internal fun SubscriptionListOperation.applyOperation(editor: SubscriptionListEditor) {
    when (this.action) {
        SubscriptionListOperationAction.SUBSCRIBE -> editor.subscribe(this.listId)
        SubscriptionListOperationAction.UNSUBSCRIBE -> editor.unsubscribe(this.listId)
    }
}