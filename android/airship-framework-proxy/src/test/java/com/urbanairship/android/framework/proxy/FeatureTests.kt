package com.urbanairship.android.framework.proxy

import com.urbanairship.PrivacyManager
import com.urbanairship.json.JsonValue
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
public class FeatureTests {

    @Test
    public fun allFeatureNames() {
        val names = Utils.featureNames(PrivacyManager.Feature.ALL)
        assertEquals(
            listOf(
                "in_app_automation",
                "message_center",
                "push",
                "analytics",
                "tags_and_attributes",
                "feature_flags",
                "contacts",
            ).sorted(),
            names.sorted()
        )
    }

    @Test
    public fun noneNames() {
        val names = Utils.featureNames(PrivacyManager.Feature.NONE)
        assertEquals(
            emptyList<String>(),
            names
        )
    }

    @Test
    public fun parseNames() {
        val names = Utils.featureNames(PrivacyManager.Feature.ALL)
        val feature = Utils.parseFeatures(JsonValue.wrapOpt(names))
        assertEquals(PrivacyManager.Feature.ALL, feature)
    }

    @Test
    public fun parseEmpty() {
        val feature = Utils.parseFeatures(JsonValue.wrapOpt(emptyList<String>()))
        assertEquals(PrivacyManager.Feature.NONE, feature)
    }

}
