import XCTest
import AirshipFrameworkProxy;
import AirshipKit;

final class ProxyConfigTests: XCTestCase {

    let fullConfig = """
    {
        "production":{
            "appKey":"production-some-app-key",
            "appSecret":"production-some-app-secret",
            "logLevel":"verbose"
        },
        "development":{
            "appKey":"development-some-app-key",
            "appSecret":"development-some-app-secret",
            "logLevel":"debug",
            "ios": {
                "logPrivacyLevel": "private"
            }
        },
        "default":{
            "appKey":"default-some-app-key",
            "appSecret":"default-some-secret",
            "logLevel":"error",
            "ios": {
                "logPrivacyLevel": "public"
            }
        },
        "site":"us",
        "initialConfigUrl":"some-url",
        "isChannelCreationDelayEnabled":false,
        "urlAllowListScopeJavaScriptInterface":[
            "*"
        ],
        "urlAllowListScopeOpenUrl":[

        ],
        "isChannelCaptureEnabled":true,
        "ios":{
            "itunesId": "neat"
        }
    }
    """

    let basicConfig = """
    {
       "development":{
          "appKey":"development-some-app-key",
          "appSecret":"development-some-app-secret"
       }
    }
    """


    func testEncodingFullConfig() throws {
        let decoded = try JSONDecoder().decode(
            ProxyConfig.self,
            from: fullConfig.data(using: .utf8)!
        )

        let encoded = try JSONEncoder().encode(decoded)

        XCTAssertEqual(
            try JSONSerialization.jsonObject(
                with: fullConfig.data(using: .utf8)!
            ) as! NSDictionary,
            try JSONSerialization.jsonObject(
                with: encoded
            ) as! NSDictionary
        )
    }

    func testPrivacyLogLevel() throws {
        let proxyConfig = try JSONDecoder().decode(
            ProxyConfig.self,
            from: fullConfig.data(using: .utf8)!
        )

        var airshipConfig = AirshipConfig()
        airshipConfig.applyProxyConfig(proxyConfig: proxyConfig)

        XCTAssertEqual(
            airshipConfig.productionLogPrivacyLevel,
            .public
        )

        XCTAssertEqual(
            airshipConfig.developmentLogPrivacyLevel,
            .private
        )
    }

    func testEncodingBasicConfig() throws {
        let decoded = try JSONDecoder().decode(
            ProxyConfig.self,
            from: fullConfig.data(using: .utf8)!
        )

        let encoded = try JSONEncoder().encode(decoded)

        XCTAssertEqual(
            try JSONSerialization.jsonObject(
                with: fullConfig.data(using: .utf8)!
            ) as! NSDictionary,
            try JSONSerialization.jsonObject(
                with: encoded
            ) as! NSDictionary
        )
    }

}
