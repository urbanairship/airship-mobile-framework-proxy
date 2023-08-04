package com.urbanairship.android.framework.proxy

import com.urbanairship.json.JsonValue
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
public class ProxyConfigTest {

    private val fullConfig: String = """
        {
           "production":{
              "appKey":"production-some-app-key",
              "appSecret":"production-some-app-secret",
              "logLevel":"verbose"
           },
           "development":{
              "appKey":"development-some-app-key",
              "appSecret":"development-some-app-secret",
              "logLevel":"debug"
           },
           "default":{
              "appKey":"default-some-app-key",
              "appSecret":"default-some-secret",
              "logLevel":"error"
           },
           "site":"us",
           "inProduction": true,
           "initialConfigUrl":"some-url",
           "isChannelCreationDelayEnabled":false,
           "urlAllowListScopeJavaScriptInterface":[
              "*"
           ],
           "urlAllowListScopeOpenUrl":[

           ],
           "isChannelCaptureEnabled":true,
           "android":{
              "notificationConfig":{
                 "largeIcon":"large icon",
                 "icon":"icon",
                 "accentColor":"#ff0000",
                 "defaultChannelId":"neat"
              }
           }
        }
    """

    private val basicConfig: String = """
        {
           "development":{
              "appKey":"development-some-app-key",
              "appSecret":"development-some-app-secret"
           }
        }
    """

    @Test
    public fun parseFullConfig() {
        val json = JsonValue.parseString(fullConfig)
        val config = ProxyConfig(json.optMap())
        assertEquals(json, config.toJsonValue())
    }

    @Test
    public fun parseBasicConfig() {
        val json = JsonValue.parseString(basicConfig)
        val config = ProxyConfig(json.optMap())
        assertEquals(json, config.toJsonValue())
    }
}
