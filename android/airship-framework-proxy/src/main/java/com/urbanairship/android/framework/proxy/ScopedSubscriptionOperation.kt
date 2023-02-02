package com.urbanairship.android.framework.proxy

import com.urbanairship.contacts.Scope
import com.urbanairship.contacts.ScopedSubscriptionListEditor
import com.urbanairship.json.JsonMap

public data class ScopedSubscriptionListOperation(
    public val listId: String,
    public val scope: Scope,
    public val action: SubscriptionListOperationAction
) {
    public constructor(json: JsonMap) : this(
        listId = json.require("listId").requireString(),
        scope = Scope.valueOf(
            json.require("scope").requireString().uppercase()
        ),
        action = SubscriptionListOperationAction.valueOf(
            json.require("action").requireString().uppercase()
        )
    )
}

internal fun ScopedSubscriptionListOperation.applyOperation(editor: ScopedSubscriptionListEditor) {
    when (this.action) {
        SubscriptionListOperationAction.SUBSCRIBE -> editor.subscribe(this.listId, this.scope)
        SubscriptionListOperationAction.UNSUBSCRIBE -> editor.unsubscribe(this.listId, this.scope)
    }
}
