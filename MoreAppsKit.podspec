Pod::Spec.new do |s|
  s.name         = 'MoreAppsKit'
  s.version      = '1.1.0'
  s.summary      = 'A lightweight, zero-maintenance Swift library for cross-promoting your iOS/macOS apps.'
  s.description  = <<-DESC
    MoreAppsKit automatically fetches localized app information from the App Store
    using the iTunes Search API. It provides ready-to-use SwiftUI views, UIKit/AppKit
    view controllers, and a data-only API — all with zero maintenance. Supports 30+
    languages, three display styles, region fallback, smart caching, and more.
  DESC

  s.homepage     = 'https://github.com/zhanggenlove/MoreAppsKit'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'zhanggen' => 'zhanggenlove@gmail.com' }
  s.source       = { :git => 'https://github.com/zhanggenlove/MoreAppsKit.git', :tag => s.version.to_s }

  s.swift_version = '5.9'
  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'

  s.source_files = 'Sources/MoreAppsKit/**/*.swift'
  s.resources    = 'Sources/MoreAppsKit/Resources/**/*.lproj'

  s.frameworks   = 'SwiftUI', 'StoreKit'
end
