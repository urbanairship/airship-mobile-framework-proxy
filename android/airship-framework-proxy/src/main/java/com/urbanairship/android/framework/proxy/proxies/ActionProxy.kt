package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.actions.ActionResult
import com.urbanairship.actions.ActionRunner
import com.urbanairship.actions.runSuspending
import com.urbanairship.json.JsonValue

public class ActionProxy internal constructor(
    private val actionRunner: () -> ActionRunner
) {
    public suspend fun runAction(name: String, value: JsonValue?): ActionResult {
        return actionRunner().runSuspending(name = name, value = value)
    }
}

