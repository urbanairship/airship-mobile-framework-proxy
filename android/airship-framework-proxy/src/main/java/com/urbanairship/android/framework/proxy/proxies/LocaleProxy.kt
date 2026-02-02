package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.UALog
import com.urbanairship.locale.LocaleManager
import java.util.Locale

public class LocaleProxy internal constructor(private val localeProvider: () -> LocaleManager) {

    public fun setCurrentLocale(localeIdentifier: String) {
        UALog.v { "setCurrentLocale called, localeIdentifier=$localeIdentifier" }
        localeProvider().setLocaleOverride(Locale.forLanguageTag(localeIdentifier))
    }

    public fun getCurrentLocale(): String {
        UALog.v { "getCurrentLocale called" }
        return localeProvider().locale.toString()
    }

    public fun clearLocale() {
        UALog.v { "clearLocale called" }
        localeProvider().setLocaleOverride(null)
    }
}
