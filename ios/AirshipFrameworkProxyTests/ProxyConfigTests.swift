import XCTest
import AirshipFrameworkProxy;

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
            "logLevel":"debug"
        },
        "default":{
            "appKey":"default-some-app-key",
            "appSecret":"default-some-secret",
            "logLevel":"error"
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
            "itunesId":"neat"
        }
    }
    """

    let basicConfig = """
    {
       "development":{
          "appKey":"development-some-app-key",
          "appSecret":"development-some-app-secret"Z
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
