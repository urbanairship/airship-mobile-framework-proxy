
Pod::Spec.new do |s|
   s.version                 = "15.3.0"
   s.name                    = "AirshipFrameworkProxy"
   s.summary                 = "Airship iOS mobile framework proxy"
   s.documentation_url       = "https://docs.airship.com/platform/mobile"
   s.homepage                = "https://www.airship.com"
   s.author                  = { "Airship" => "support@airship.com" }

   s.license                 = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
   s.source                  = { :git => "https://github.com/urbanairship/airship-mobile-framework-proxy.git", :tag => s.version.to_s }

   s.module_name             = "AirshipFrameworkProxy"
   s.ios.deployment_target   = "16.0"
   s.requires_arc            = true
   s.swift_version           = "6.0"
   s.source_files            = "ios/AirshipFrameworkProxy/**/*.{h,m,swift}"
   s.dependency                'Airship', "20.2.0"
   s.source_files            = 'ios/AirshipFrameworkProxyLoader/**/*.{swift,h,m,c,cc,mm,cpp}', 'ios/AirshipFrameworkProxy/**/*.{swift,h,m,c,cc,mm,cpp}'
end


