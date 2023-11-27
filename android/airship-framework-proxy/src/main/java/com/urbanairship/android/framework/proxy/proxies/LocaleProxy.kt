package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.locale.LocaleManager
import java.util.Locale

public class LocaleProxy internal constructor(private val localeProvider: () -> LocaleManager) {

    public fun setCurrentLocale(localeIdentifier: String) {
        val localeParams = localeIdentifier.split("-", "_")
        localeProvider().setLocaleOverride(Locale(localeParams[0], if (localeParams.size > 1) localeParams[1] else ""))
    }

    public fun getCurrentLocale(): String {
        return localeProvider().locale.toString()
    }

    public fun clearLocale() {
        localeProvider().setLocaleOverride(null)
    }
}
