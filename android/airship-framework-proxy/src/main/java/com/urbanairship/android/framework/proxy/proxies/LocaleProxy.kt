package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.locale.LocaleManager
import java.util.*

public class LocaleProxy internal constructor(private val localeProvider: () -> LocaleManager) {

    public fun setCurrentLocale(localeIdentifier: String) {
        localeProvider().setLocaleOverride(Locale(localeIdentifier))
    }

    public fun getCurrentLocale(): String {
        return localeProvider().locale.toString()
    }

    public fun clearLocale() {
        localeProvider().setLocaleOverride(null)
    }
}