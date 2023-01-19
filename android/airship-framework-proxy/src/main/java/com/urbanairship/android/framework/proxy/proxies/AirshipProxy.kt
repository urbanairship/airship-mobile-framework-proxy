/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.proxies

import android.annotation.SuppressLint
import android.content.Context
import com.urbanairship.Autopilot
import com.urbanairship.UAirship
import com.urbanairship.android.framework.proxy.ProxyConfig
import com.urbanairship.android.framework.proxy.ProxyStore
import com.urbanairship.json.JsonValue


public class AirshipProxy(
    private val context: Context,
    internal val proxyStore: ProxyStore
) {

    public val analytics: AnalyticsProxy = AnalyticsProxy {
        ensureTakeOff()
        UAirship.shared().analytics
    }

    public val push: PushProxy = PushProxy(
        context,
        proxyStore,
        permissionsManagerProvider = {
            ensureTakeOff()
            UAirship.shared().permissionsManager
        },
        pushProvider = {
            ensureTakeOff()
            UAirship.shared().pushManager
        }
    )

    public fun takeOff(config: JsonValue): Boolean {
        return takeOff(ProxyConfig(config.optMap()))
    }

    public fun takeOff(config: ProxyConfig): Boolean {
        proxyStore.airshipConfig = config
        Autopilot.automaticTakeOff(context)
        return isFlying()
    }

    public fun isFlying(): Boolean {
        return UAirship.isFlying() || UAirship.isTakingOff()
    }

    public companion object {
        @SuppressLint("StaticFieldLeak")
        @Volatile
        private var sharedInstance: AirshipProxy? = null
        private val sharedInstanceLock = Any()

        @JvmStatic
        public fun shared(context: Context): AirshipProxy {
            synchronized(sharedInstanceLock) {
                if (sharedInstance == null) {
                    sharedInstance = AirshipProxy(context, ProxyStore(context))
                }
                return sharedInstance!!
            }
        }
    }

    private fun ensureTakeOff() {
        if (!UAirship.isFlying() || !UAirship.isTakingOff()) {
            throw java.lang.IllegalStateException("Takeoff not called.")
        }
    }
}



//
//
//    /**
//     * Helper to determine user notifications authorization status
//     */
//    fun checkOptIn() {
//        if (!Utils.ensureAirshipReady()) {
//            return
//        }
//        val optIn = UAirship.shared().pushManager.isOptIn
//        if (preferences.optInStatus != optIn) {
//            preferences.optInStatus = optIn
//            val optInEvent: Event = NotificationOptInEvent(optIn)
//            EventEmitter.shared().sendEvent(optInEvent)
//        }
//    }
//
//    /**
//     * Helper method to parse a String features array into [PrivacyManager.Feature].
//     *
//     * @param features The String features to parse.
//     * @return The resulting feature flag.
//     */
//    @PrivacyManager.Feature
//    @Throws(IllegalArgumentException::class)
//    private fun parseFeatures(features: ReadableArray): Int {
//        var result = PrivacyManager.FEATURE_NONE        for (i in 0 until features.size()) {
//            result = result or Utils.parseFeature(features.getString(i))
//        }
//        return result
//    }
//
//    companion object {
//        private const val TAG_OPERATION_GROUP_NAME = "group"
//        private const val TAG_OPERATION_TYPE = "operationType"
//        private const val TAG_OPERATION_TAGS = "tags"
//        private const val TAG_OPERATION_ADD = "add"
//        private const val TAG_OPERATION_REMOVE = "remove"
//        private const val TAG_OPERATION_SET = "set" private const
//        val ATTRIBUTE_OPERATION_KEY = "key"
//        private const val ATTRIBUTE_OPERATION_VALUE = "value"
//        private const val ATTRIBUTE_OPERATION_TYPE = "action"
//        private const val ATTRIBUTE_OPERATION_SET = "set"
//        private const val ATTRIBUTE_OPERATION_REMOVE = "remove"
//        private const val ATTRIBUTE_OPERATION_VALUETYPE = "type" private const
//        val SUBSCRIBE_LIST_OPERATION_LISTID = "listId"
//        private const val SUBSCRIBE_LIST_OPERATION_TYPE = "type"
//        private const val SUBSCRIBE_LIST_OPERATION_SCOPE = "scope" const
//        val NOTIFICATION_ICON_KEY = "icon"
//        const val NOTIFICATION_LARGE_ICON_KEY = "largeIcon"
//        const val ACCENT_COLOR_KEY = "accentColor"
//        const val DEFAULT_CHANNEL_ID_KEY = "defaultChannelId" const
//        val CLOSE_MESSAGE_CENTER = "CLOSE" private const
//        val INVALID_FEATURE_ERROR_CODE = "INVALID_FEATURE"
//        private const val INVALID_FEATURE_ERROR_MESSAGE =
//            "Invalid feature, cancelling the action." private
//        val BG_EXECUTOR: Executor = Executors.newCachedThreadPool()
//
//        /**
//         * Helper method to apply tag group changes.
//         *
//         * @param editor     The tag group editor.
//         * @param operations A list of tag group operations.
//         */
//        private fun applyTagGroupOperations(editor: TagGroupsEditor, operations: ReadableArray) {
//            for (i in 0 until operations.size()) {
//                val operation = operations.getMap(i)
//                val group = operation.getString(TAG_OPERATION_GROUP_NAME)
//                val tags = operation.getArray(TAG_OPERATION_TAGS)
//                val operationType =
//                    operation.getString(TAG_OPERATION_TYPE)                if (group == null || tags == null || operationType == null) {
//                    continue
//                }
//                val tagSet = HashSet<String>()
//                for (j in 0 until tags.size()) {
//                    tagSet.add(tags.getString(j))
//                }                when (operationType) {
//                    TAG_OPERATION_ADD -> {
//                        editor.addTags(group, tagSet)
//                    }
//                    TAG_OPERATION_REMOVE -> {
//                        editor.removeTags(group, tagSet)
//                    }
//                    TAG_OPERATION_SET -> {
//                        editor.setTags(group, tagSet)
//                    }
//                }
//            }
//            editor.apply()
//        }
//
//        /**
//         * Helper method to apply attribute changes.
//         *
//         * @param editor     The attribute editor.
//         * @param operations A list of attribute operations.
//         */
//        private fun applyAttributeOperations(editor: AttributeEditor, operations: ReadableArray) {
//            for (i in 0 until operations.size()) {
//                val operation = operations.getMap(i)
//                val action = operation.getString(ATTRIBUTE_OPERATION_TYPE)
//                val key =
//                    operation.getString(ATTRIBUTE_OPERATION_KEY)                if (action == null || key == null) {
//                    continue
//                }                if (ATTRIBUTE_OPERATION_SET == action) {
//                    val valueType = operation.getString(ATTRIBUTE_OPERATION_VALUETYPE)
//                    if ("string" == valueType) {
//                        val value = operation.getString(ATTRIBUTE_OPERATION_VALUE) ?: continue
//                        editor.setAttribute(key, value)
//                    } else if ("number" == valueType) {
//                        val value = operation.getDouble(ATTRIBUTE_OPERATION_VALUE)
//                        editor.setAttribute(key, value)
//                    } else if ("date" == valueType) {
//                        val value = operation.getDouble(ATTRIBUTE_OPERATION_VALUE)
//                        // JavaScript's date type doesn't pass through the JS to native bridge. Dates are instead serialized as milliseconds since epoch.
//                        editor.setAttribute(key, Date(value.toLong()))
//                    }
//                } else if (ATTRIBUTE_OPERATION_REMOVE == action) {
//                    editor.removeAttribute(key)
//                }
//            }
//            editor.apply()
//        }
//
//        private fun toWritableArray(strings: Collection<String>): WritableArray {
//            val result = Arguments.createArray()
//            for (value in strings) {
//                result.pushString(value)
//            }
//            return result
//        }
//    }
//
//}