package com.urbanairship.android.framework.proxy

import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue
import com.urbanairship.json.jsonMapOf
import com.urbanairship.json.optionalField
import com.urbanairship.json.requireField
import com.urbanairship.push.PushNotificationStatus

public data class NotificationStatus(
    public val isUserNotificationsEnabled: Boolean,
    public val areNotificationsAllowed: Boolean,
    public val isPushPrivacyFeatureEnabled: Boolean,
    public val isPushTokenRegistered: Boolean,
    public val isUserOptedIn: Boolean,
    public val isOptedIn: Boolean,
    public val notificationPermissionStatus: String?
) : JsonSerializable {

    public constructor(value: JsonValue): this(
        isUserNotificationsEnabled = value.requireMap().requireField("isUserNotificationsEnabled"),
        areNotificationsAllowed = value.requireMap().requireField("areNotificationsAllowed"),
        isPushPrivacyFeatureEnabled = value.requireMap().requireField("isPushPrivacyFeatureEnabled"),
        isPushTokenRegistered = value.requireMap().requireField("isPushTokenRegistered"),
        isUserOptedIn = value.requireMap().requireField("isUserOptedIn"),
        isOptedIn = value.requireMap().requireField("isOptedIn"),
        notificationPermissionStatus = value.requireMap().optionalField("notificationPermissionStatus")
    )

    public constructor(status: PushNotificationStatus, notificationPermissionStatus: String?) : this(
        isUserNotificationsEnabled = status.isUserNotificationsEnabled,
        areNotificationsAllowed = status.areNotificationsAllowed,
        isPushPrivacyFeatureEnabled = status.isPushPrivacyFeatureEnabled,
        isPushTokenRegistered = status.isPushTokenRegistered,
        isUserOptedIn = status.isUserOptedIn,
        isOptedIn = status.isOptIn,
        notificationPermissionStatus = notificationPermissionStatus
    )

    override fun toJsonValue(): JsonValue = jsonMapOf(
            "isUserNotificationsEnabled" to this.isUserNotificationsEnabled,
            "areNotificationsAllowed" to this.areNotificationsAllowed,
            "isPushPrivacyFeatureEnabled" to this.isPushPrivacyFeatureEnabled,
            "isPushTokenRegistered" to this.isPushTokenRegistered,
            "isUserOptedIn" to this.isUserOptedIn,
            "isOptedIn" to this.isOptedIn,
            "notificationPermissionStatus" to this.notificationPermissionStatus
    ).toJsonValue()
}
