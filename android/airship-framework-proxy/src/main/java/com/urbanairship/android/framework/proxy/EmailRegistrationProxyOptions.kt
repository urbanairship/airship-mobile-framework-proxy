package com.urbanairship.android.framework.proxy

import com.urbanairship.contacts.EmailRegistrationOptions
import com.urbanairship.json.JsonMap
import java.util.Date

public data class EmailRegistrationProxyOptions(
    public val transactionalOptedIn: Long?,
    public val commercialOptedIn: Long?,
    public val properties: JsonMap?,
    public val doubleOptIn: Boolean
) {
    public constructor(json: JsonMap) : this(
        transactionalOptedIn = json.opt("transactionalOptedIn").let {
            if (it.isNull) null else it.getLong(-1).takeIf { ms -> ms >= 0 }
        },
        commercialOptedIn = json.opt("commercialOptedIn").let {
            if (it.isNull) null else it.getLong(-1).takeIf { ms -> ms >= 0 }
        },
        properties = json.opt("properties").map.takeIf { it.isNotEmpty() },
        doubleOptIn = json.opt("doubleOptIn").getBoolean(false)
    )

    public fun toEmailRegistrationOptions(): EmailRegistrationOptions {
        val transactionalDate = transactionalOptedIn?.let { Date(it) }
        val commercialDate = commercialOptedIn?.let { Date(it) }

        return if (commercialDate != null) {
            EmailRegistrationOptions.commercialOptions(
                commercialDate,
                transactionalDate,
                properties
            )
        } else {
            EmailRegistrationOptions.options(
                transactionalDate,
                properties,
                doubleOptIn
            )
        }
    }
}
