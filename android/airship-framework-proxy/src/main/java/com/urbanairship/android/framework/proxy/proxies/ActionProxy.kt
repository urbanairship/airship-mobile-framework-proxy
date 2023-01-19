package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.PendingResult
import com.urbanairship.actions.ActionResult
import com.urbanairship.actions.ActionRunRequestFactory
import com.urbanairship.json.JsonValue

public class ActionProxy internal constructor(
    private val actionRunRequestFactory: ActionRunRequestFactory
) {
    public fun runAction(name: String, value: JsonValue?): PendingResult<ActionResult> {
        val pendingResult = PendingResult<ActionResult>()
        actionRunRequestFactory.createActionRequest(name)
            .setValue(value)
            .run { _, result ->
                pendingResult.result = result
            }

        return pendingResult
    }
}

