# MoreAppsKit

[中文](README_zh.md) | [日本語](README_ja.md) | [한국어](README_ko.md)

A lightweight, zero-maintenance Swift library for cross-promoting your iOS/macOS apps — automatically fetching localized app information from the App Store.

<p align="center">
  <img src="preview/preview1.png" width="230" />
  <img src="preview/preview3.png" width="230" />
  <img src="preview/preview2.png" width="230" />
</p>

## Features

- **Zero Maintenance** — No hardcoded app names, icons, or URLs. New apps appear automatically.
- **Locale-Aware** — App names, descriptions, and prices are served in the user's language and region.
- **Region Fallback** — If your apps aren't available in the user's region, automatically falls back to `us`.
- **Current App Support** — Show the current app at the top with built-in Rate & Share buttons (auto-discovers app ID).
- **Display Options** — Control which elements are visible (rating, price, description). Great when your rating is... still growing.
- **Data-Only API** — Fetch raw `[MoreApp]` data and build your own custom UI.
- **Full Page View** — App Store-inspired full list with search, for developers with many apps.
- **Auto-Exclude** — The current running app is automatically filtered from "other apps" list.
- **Offline-Ready** — Two-tier caching (memory + disk) with stale-data fallback when offline.
- **Three Display Styles** — Compact list rows, rich cards, or horizontal banners.
- **UIKit & AppKit** — Provides `MoreAppsViewController` for UIKit/AppKit projects.
- **Localized** — Built-in support for 30+ languages.
- **iOS 15+** — Supports iOS 15+ and macOS 12+.

## Installation

### Swift Package Manager

Add MoreAppsKit to your project in Xcode:

1. **File → Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/zhanggenlove/MoreAppsKit
   ```
3. Select **Up to Next Major Version** from `1.0.0`

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/zhanggenlove/MoreAppsKit", from: "1.0.0")
]
```

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'MoreAppsKit', '~> 1.0'
```

Then run `pod install`.

## Quick Start

### 1. Configure (once at app launch)

```swift
import MoreAppsKit

@main
struct MyApp: App {
    init() {
        MoreAppsKit.configure(developerID: "YOUR_DEVELOPER_ID")
    }
    // ...
}
```

### 2. Display

```swift
import MoreAppsKit

struct SettingsView: View {
    var body: some View {
        Form {
            MoreAppsView()
        }
    }
}
```

That's it. The view handles loading, caching, error states, and tapping automatically.

## Display Styles

### Compact (default)

```swift
MoreAppsView()
MoreAppsView(style: .compact)
```

### Card

```swift
MoreAppsView(style: .card)
```

### Banner

```swift
MoreAppsView(style: .banner)
```

## Display Options

Control which elements appear in the built-in views:

```swift
// Hide rating and price (name + icon only)
MoreAppsView(displayOptions: .minimal)

// Custom: hide rating, show only 3 apps with "See All" link
MoreAppsView(
    style: .card,
    displayOptions: .init(showRating: false, maxCount: 3)
)

// Show everything (default)
MoreAppsView(displayOptions: .all)
```

## Current App + Rate & Share

Show the current app at the top with built-in Rate and Share buttons:

```swift
MoreAppsKit.configure(
    MoreAppsConfig(
        developerID: "1499619759",
        showCurrentApp: true
    )
)
```

No need to hardcode your App Store ID — it's auto-discovered from the API.

## Data-Only API

Fetch raw data and build your own custom UI:

```swift
let apps = try await MoreAppsKit.fetchApps()
for app in apps {
    print("\(app.name) — \(app.storeURL)")
}

// Auto-discover the current app
if let current = await MoreAppsKit.currentApp() {
    print("Current app ID: \(current.id)")
}

// Request a review (no hardcoded app ID needed)
await MoreAppsKit.requestReview()
```

## Full Page View (App Store Style)

When you have many apps, show a searchable full-page list:

```swift
// Automatic: set maxCount and a "See All" link appears
MoreAppsView(
    style: .card,
    displayOptions: .init(maxCount: 3)
)

// Manual: navigate directly
NavigationLink("All Apps") {
    MoreAppsFullView(apps: myApps)
}
```

## UIKit Integration

MoreAppsKit provides `MoreAppsViewController` — a ready-to-use `UIHostingController` subclass.

```swift
// Push
let vc = MoreAppsViewController(style: .card)
navigationController?.pushViewController(vc, animated: true)

// Present modally
let nav = MoreAppsViewController.wrapped(style: .compact)
present(nav, animated: true)

// Embed as child
let vc = MoreAppsViewController(style: .banner)
addChild(vc)
containerView.addSubview(vc.view)
vc.view.frame = containerView.bounds
vc.didMove(toParent: self)
```

## macOS (AppKit) Integration

On macOS, `MoreAppsViewController` wraps `NSHostingController`:

```swift
let vc = MoreAppsViewController(style: .card)
presentAsSheet(vc)
```

## Advanced Configuration

```swift
MoreAppsKit.configure(
    MoreAppsConfig(
        developerID: "1499619759",
        excludeBundleIds: ["com.example.beta"],
        platformFilter: .iOS,
        cacheDuration: 3600 * 12,
        regionFallback: true,
        showCurrentApp: true,
        displayOptions: .init(
            showRating: false,
            showPrice: true,
            showDescription: true,
            maxCount: 5
        ),
        onAppTapped: { app in
            Analytics.track("more_app_tapped", properties: ["app": app.name])
        }
    )
)
```

## How It Works

1. **iTunes Search API** — Fetches your apps via `itunes.apple.com/lookup?id=<devID>&entity=software&country=<cc>`
2. **Locale Resolution** — Country code is derived from `Locale.current`, ensuring localized names, descriptions, and pricing
3. **Region Fallback** — If the local region returns no apps, automatically retries with "us"
4. **Smart Caching** — Results are cached in memory and on disk (24h default). Stale cache is used as fallback when offline.
5. **Auto-Filter** — The current app (`Bundle.main.bundleIdentifier`) is automatically excluded from the "other apps" list
6. **App ID Discovery** — The current app's Store ID is resolved from the API, enabling Rate and Share without hardcoding

## API Reference

| Type | Description |
|------|-------------|
| `MoreAppsKit.configure(developerID:)` | Quick setup with developer ID |
| `MoreAppsKit.configure(_:)` | Full setup with `MoreAppsConfig` |
| `MoreAppsKit.fetchApps()` | Async — returns `[MoreApp]` for custom UI |
| `MoreAppsKit.currentApp()` | Async — discovers the current app from the Store |
| `MoreAppsKit.requestReview()` | Async — triggers App Store review prompt |
| `MoreAppsKit.clearCache()` | Manually clear cached data |
| `MoreAppsView` | Drop-in SwiftUI view component |
| `MoreAppsFullView` | Full-page App Store style list |
| `MoreAppsViewController` | UIKit/AppKit view controller (push, present, or embed) |
| `MoreAppsFullViewController` | UIKit/AppKit full-page list view controller |
| `MoreApp` | Data model for a single app |
| `MoreAppsConfig` | Configuration options |
| `DisplayOptions` | Controls visible elements |
| `MoreAppsStyle` | `.compact` / `.card` / `.banner` |

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## License

MIT License. See [LICENSE](LICENSE) for details.
