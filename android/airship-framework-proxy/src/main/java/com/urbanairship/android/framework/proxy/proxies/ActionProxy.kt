package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.PendingResult
import com.urbanairship.actions.ActionResult
import com.urbanairship.actions.ActionRunner
import com.urbanairship.json.JsonValue

public class ActionProxy internal constructor(
    private val actionRunner: () -> ActionRunner
) {
    public fun runAction(name: String, value: JsonValue?): PendingResult<ActionResult> {
        val pendingResult = PendingResult<ActionResult>()
        actionRunner().run(name = name, value = value) { _, result ->
            pendingResult.result = result
        }

        return pendingResult
    }
}

