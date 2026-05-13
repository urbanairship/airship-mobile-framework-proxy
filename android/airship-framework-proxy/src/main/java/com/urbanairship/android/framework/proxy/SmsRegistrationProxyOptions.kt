package com.urbanairship.android.framework.proxy

import com.urbanairship.contacts.SmsRegistrationOptions
import com.urbanairship.json.JsonMap

public data class SmsRegistrationProxyOptions(
    public val senderId: String
) {
    public constructor(json: JsonMap) : this(
        senderId = json.require("senderId").requireString()
    )

    public fun toSmsRegistrationOptions(): SmsRegistrationOptions {
        return SmsRegistrationOptions.options(senderId)
    }
}
