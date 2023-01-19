package com.urbanairship.android.framework.proxy.proxies

public class ContactProxy {

//    /**
//     * Sets the named user.
//     *
//     * @param namedUser The named user ID.
//     */
//    fun setNamedUser(namedUser: String?) {
//        var mutableNamedUser = namedUser        if (!Utils.ensureAirshipReady()) {
//            return
//        } mutableNamedUser ?. let { value ->
//            mutableNamedUser = value.trim { it <= ' ' }
//        }        if (UAStringUtil.isEmpty(mutableNamedUser)) {
//            UAirship.shared().contact.reset()
//        } else {
//            UAirship.shared().contact.identify(mutableNamedUser!!)
//        }
//    }
//
//    /**
//     * Gets the named user.
//     *
//     * @param promise The JS promise.
//     */
//    fun getNamedUser(promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        promise.resolve(UAirship.shared().contact.namedUserId)
//    }
//


//    /**
//     * Gets the current subscription lists.
//     *
//     * @param types   The types of
//     * @param promise The JS promise.
//     */
//    fun getSubscriptionLists(types: ReadableArray?, promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        PluginLogger.debug("getSubscriptionLists($types)")
//        val parsedTypes: MutableSet<SubscriptionListType> = HashSet()
//        types?.let {
//            for (i in 0 until it.size()) {
//                try {
//                    val type = SubscriptionListType.valueOf(it.getString(i).uppercase(Locale.ROOT))
//                    parsedTypes.add(type)
//                } catch (e: Exception) {
//                    promise.reject(e)
//                    return
//                }
//            }
//        }        if (parsedTypes.isEmpty()) {
//            promise.reject(Exception("Failed to fetch subscription lists, no types."))
//            return
//        } BG_EXECUTOR . execute {
//            val resultMap = Arguments.createMap()
//            try {
//                val ua = UAirship.shared()
//                for (type in parsedTypes) {
//                    when (type) {
//                        SubscriptionListType.CHANNEL -> {
//                            val channelSubs = ua.channel.getSubscriptionLists(true).get()
//                            if (channelSubs == null) {
//                                promise.reject(Exception("Failed to fetch channel subscription lists."))
//                                return@execute
//                            }
//                            resultMap.putArray(
//                                "channel",
//                                toWritableArray(channelSubs)
//                            )
//                        }
//                        SubscriptionListType.CONTACT -> {
//                            val contactSubs = ua.contact.getSubscriptionLists(true).get()
//                            if (contactSubs == null) {
//                                promise.reject(Exception("Failed to fetch contact subscription lists."))
//                                return@execute
//                            }
//                            val contactSubsMap = Arguments.createMap()
//                            for ((key, value) in contactSubs) {
//                                val scopesArray = Arguments.createArray()
//                                for (s in value) {
//                                    scopesArray.pushString(s.toString())
//                                }
//                                contactSubsMap.putArray(key!!, scopesArray)
//                            }
//                            resultMap.putMap("contact", contactSubsMap)
//                        }
//                    }
//                }
//                promise.resolve(resultMap)
//            } catch (e: Exception) {
//                promise.reject(e)
//            }
//        }
//    }


//    /**
//     * Edits the contact tag groups.
//     * Operations should each be a map with the following:
//     * - operationType: Either add or remove
//     * - group: The group to modify
//     * - tags: The tags to add or remove.
//     *
//     * @param operations An array of operations.
//     */
//    fun editContactTagGroups(operations: ReadableArray) {
//        if (!Utils.ensureAirshipReady()) {
//            return
//        }
//        applyTagGroupOperations(UAirship.shared().contact.editTagGroups(), operations)
//    }

//
//    /**
//     * Edits the contact attributes.
//     * Operations should each be a map with the following:
//     * - action: Either set or remove
//     * - value: The group to modify
//     * - key: The tags to add or remove.
//     *
//     * @param operations An array of operations.
//     */
//    fun editContactAttributes(operations: ReadableArray) {
//        if (!Utils.ensureAirshipReady()) {
//            return
//        }
//        applyAttributeOperations(UAirship.shared().contact.editAttributes(), operations)
//    }

//
//    /**
//     * Edit subscription lists associated with the current Channel.
//     *
//     *
//     * List updates should each be a map with the following:
//     * - type: Either subscribe or unsubscribe.
//     * - listId: ID of the subscription list to subscribe to or unsubscribe from.
//     * - scope: Subscription scope (one of: app, web, sms, email).
//     *
//     * @param scopedSubscriptionListUpdates The subscription list updates.
//     */
//    fun editContactSubscriptionLists(scopedSubscriptionListUpdates: ReadableArray) {
//        if (!Utils.ensureAirshipReady()) {
//            return
//        }
//        val editor = UAirship.shared().contact.editSubscriptionLists()
//        for (i in 0 until scopedSubscriptionListUpdates.size()) {
//            val subscriptionListUpdate = scopedSubscriptionListUpdates.getMap(i)
//            val listId = subscriptionListUpdate.getString(SUBSCRIBE_LIST_OPERATION_LISTID)
//            val type = subscriptionListUpdate.getString(SUBSCRIBE_LIST_OPERATION_TYPE)
//            val scopeString = subscriptionListUpdate.getString(SUBSCRIBE_LIST_OPERATION_SCOPE)
//            if (listId == null || type == null || scopeString == null) {
//                continue
//            }
//            val scope: Scope = try {
//                Scope.valueOf(scopeString.uppercase(Locale.ROOT))
//            } catch (e: IllegalArgumentException) {
//                continue
//            }
//            if ("subscribe" == type) {
//                editor.subscribe(listId, scope)
//            } else if ("unsubscribe" == type) {
//                editor.unsubscribe(listId, scope)
//            }
//        }
//        editor.apply()
//    }
}