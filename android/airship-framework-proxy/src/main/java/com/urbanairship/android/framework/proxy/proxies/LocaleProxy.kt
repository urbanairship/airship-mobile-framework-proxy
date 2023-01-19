package com.urbanairship.android.framework.proxy.proxies

public class LocaleProxy {
    /**
    //     * Overriding the locale.
    //     *
    //     * @param localeIdentifier The locale identifier.
    //     */
//    fun setCurrentLocale(localeIdentifier: String) {
//        if (!Utils.ensureAirshipReady()) {
//            return
//        }
//        UAirship.shared().setLocaleOverride(Locale(localeIdentifier))
//    }
//
//    /**
//     * Getting the locale currently used by Airship.
//     */
//    fun getCurrentLocale(promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        val airshipLocale = UAirship.shared().locale
//        promise.resolve(airshipLocale.language)
//    }
//
//    /**
//     * Resets the current locale.
//     */
//    fun clearLocale() {
//        UAirship.shared().setLocaleOverride(null)
//    }
}