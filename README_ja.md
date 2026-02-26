# MoreAppsKit

[English](README.md) | [中文](README_zh.md) | [한국어](README_ko.md)

iOS/macOS アプリのクロスプロモーションを実現する、軽量でメンテナンス不要の Swift ライブラリ — App Store からローカライズされたアプリ情報を自動取得します。

<p align="center">
  <img src="preview/preview1.png" width="230" />
  <img src="preview/preview3.png" width="230" />
  <img src="preview/preview2.png" width="230" />
</p>

## 特徴

- **メンテナンス不要** — アプリ名、アイコン、URL のハードコード不要。新しいアプリは自動的に表示されます。
- **ロケール対応** — アプリ名、説明、価格はユーザーの言語と地域に合わせて提供されます。
- **リージョンフォールバック** — ユーザーの地域でアプリが利用できない場合、自動的に米国にフォールバックします。
- **現在のアプリ対応** — 現在のアプリを上部に表示し、評価・共有ボタンを内蔵（App ID を自動検出）。
- **表示オプション** — 表示する要素（評価、価格、説明）を制御可能。評価が成長中の時に便利です。
- **データ専用 API** — 生の `[MoreApp]` データを取得し、独自の UI を構築可能。
- **フルページビュー** — App Store 風の検索可能なフルリスト。アプリが多い開発者向け。
- **自動除外** — 現在実行中のアプリは「他のアプリ」リストから自動的にフィルタリングされます。
- **オフライン対応** — 2 層キャッシュ（メモリ + ディスク）で、オフライン時は期限切れキャッシュで対応。
- **3 つの表示スタイル** — コンパクトリスト、リッチカード、横スクロールバナー。
- **UIKit & AppKit** — UIKit/AppKit プロジェクト向けに `MoreAppsViewController` を提供。
- **多言語対応** — 30 以上の言語をビルトインサポート。
- **iOS 15+** — iOS 15+ および macOS 12+ に対応。

## インストール

### Swift Package Manager

Xcode で MoreAppsKit を追加：

1. **File → Add Package Dependencies...**
2. リポジトリ URL を入力：
   ```
   https://github.com/zhanggenlove/MoreAppsKit
   ```
3. **Up to Next Major Version** を選択、開始バージョン `1.0.0`

または `Package.swift` に追加：

```swift
dependencies: [
    .package(url: "https://github.com/zhanggenlove/MoreAppsKit", from: "1.0.0")
]
```

### CocoaPods

`Podfile` に以下を追加：

```ruby
pod 'MoreAppsKit', '~> 1.0'
```

その後 `pod install` を実行してください。

## クイックスタート

### 1. 設定（アプリ起動時に一度だけ）

```swift
import MoreAppsKit

@main
struct MyApp: App {
    init() {
        MoreAppsKit.configure(developerID: "あなたの開発者ID")
    }
    // ...
}
```

### 2. 表示

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

これだけです。ビューがローディング、キャッシュ、エラー状態、タップ処理を自動的に行います。

## 表示スタイル

### コンパクト（デフォルト）

```swift
MoreAppsView()
MoreAppsView(style: .compact)
```

### カード

```swift
MoreAppsView(style: .card)
```

### バナー

```swift
MoreAppsView(style: .banner)
```

## 表示オプション

ビルトインビューに表示する要素を制御：

```swift
// 評価と価格を非表示（アイコン + 名前のみ）
MoreAppsView(displayOptions: .minimal)

// カスタム：評価を非表示、3 アプリのみ表示し「すべて表示」リンクを表示
MoreAppsView(
    style: .card,
    displayOptions: .init(showRating: false, maxCount: 3)
)

// すべて表示（デフォルト）
MoreAppsView(displayOptions: .all)
```

## 現在のアプリ + 評価・共有

現在のアプリを上部に表示し、評価・共有ボタンを内蔵：

```swift
MoreAppsKit.configure(
    MoreAppsConfig(
        developerID: "1499619759",
        showCurrentApp: true
    )
)
```

App Store ID のハードコード不要 — API から自動検出されます。

## データ専用 API

生データを取得し、独自の UI を構築：

```swift
let apps = try await MoreAppsKit.fetchApps()
for app in apps {
    print("\(app.name) — \(app.storeURL)")
}

// 現在のアプリを自動検出
if let current = await MoreAppsKit.currentApp() {
    print("現在のアプリ ID: \(current.id)")
}

// レビューをリクエスト（App ID のハードコード不要）
await MoreAppsKit.requestReview()
```

## フルページビュー（App Store スタイル）

アプリが多い場合、検索可能なフルリストを表示：

```swift
// 自動：maxCount を設定すると「すべて表示」リンクが表示
MoreAppsView(
    style: .card,
    displayOptions: .init(maxCount: 3)
)

// 手動：直接ナビゲーション
NavigationLink("すべてのアプリ") {
    MoreAppsFullView(apps: myApps)
}
```

## UIKit 統合

MoreAppsKit は `MoreAppsViewController` を提供 — すぐに使える `UIHostingController` サブクラスです。

```swift
// Push
let vc = MoreAppsViewController(style: .card)
navigationController?.pushViewController(vc, animated: true)

// モーダル表示
let nav = MoreAppsViewController.wrapped(style: .compact)
present(nav, animated: true)

// 子コントローラとして埋め込み
let vc = MoreAppsViewController(style: .banner)
addChild(vc)
containerView.addSubview(vc.view)
vc.view.frame = containerView.bounds
vc.didMove(toParent: self)
```

## macOS (AppKit) 統合

macOS では、`MoreAppsViewController` は `NSHostingController` をラップします：

```swift
let vc = MoreAppsViewController(style: .card)
presentAsSheet(vc)
```

## 高度な設定

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

## 仕組み

1. **iTunes Search API** — `itunes.apple.com/lookup?id=<devID>&entity=software&country=<cc>` でアプリを取得
2. **ロケール解決** — 国コードは `Locale.current` から取得し、名前・説明・価格のローカライズを保証
3. **リージョンフォールバック** — ローカルリージョンで結果がない場合、自動的に "us" でリトライ
4. **スマートキャッシュ** — 結果をメモリとディスクにキャッシュ（デフォルト 24 時間）。オフライン時は期限切れキャッシュで対応
5. **自動フィルタ** — 現在のアプリ（`Bundle.main.bundleIdentifier`）は「他のアプリ」リストから自動除外
6. **App ID 自動検出** — 現在のアプリの Store ID を API から自動取得、ハードコードなしで評価・共有を実現

## API リファレンス

| タイプ | 説明 |
|--------|------|
| `MoreAppsKit.configure(developerID:)` | 開発者 ID でクイック設定 |
| `MoreAppsKit.configure(_:)` | `MoreAppsConfig` でフル設定 |
| `MoreAppsKit.fetchApps()` | 非同期 — カスタム UI 用に `[MoreApp]` を返す |
| `MoreAppsKit.currentApp()` | 非同期 — Store から現在のアプリを検出 |
| `MoreAppsKit.requestReview()` | 非同期 — App Store レビュープロンプトを起動 |
| `MoreAppsKit.clearCache()` | キャッシュデータを手動クリア |
| `MoreAppsView` | ドロップイン SwiftUI ビューコンポーネント |
| `MoreAppsFullView` | フルページ App Store スタイルリスト |
| `MoreAppsViewController` | UIKit/AppKit ビューコントローラ（push、present、埋め込み） |
| `MoreAppsFullViewController` | UIKit/AppKit フルページリストビューコントローラ |
| `MoreApp` | 単一アプリのデータモデル |
| `MoreAppsConfig` | 設定オプション |
| `DisplayOptions` | 表示要素の制御 |
| `MoreAppsStyle` | `.compact` / `.card` / `.banner` |

## 動作要件

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## ライセンス

MIT ライセンス。詳細は [LICENSE](LICENSE) をご覧ください。
