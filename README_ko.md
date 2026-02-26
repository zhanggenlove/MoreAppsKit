# MoreAppsKit

[English](README.md) | [中文](README_zh.md) | [日本語](README_ja.md)

iOS/macOS 앱의 크로스 프로모션을 위한 경량 Swift 라이브러리 — App Store에서 현지화된 앱 정보를 자동으로 가져옵니다.

<p align="center">
  <img src="preview/preview1.png" width="230" />
  <img src="preview/preview3.png" width="230" />
  <img src="preview/preview2.png" width="230" />
</p>

## 특징

- **무관리** — 앱 이름, 아이콘, URL을 하드코딩할 필요 없음. 새 앱이 자동으로 표시됩니다.
- **로케일 인식** — 앱 이름, 설명, 가격이 사용자의 언어와 지역에 맞게 제공됩니다.
- **지역 폴백** — 사용자 지역에서 앱을 사용할 수 없는 경우 자동으로 미국으로 폴백합니다.
- **현재 앱 지원** — 상단에 현재 앱을 표시하고, 평가 및 공유 버튼 내장 (App ID 자동 감지).
- **표시 옵션** — 표시할 요소 (평점, 가격, 설명) 제어 가능. 평점이 아직 성장 중일 때 유용합니다.
- **데이터 전용 API** — 원시 `[MoreApp]` 데이터를 가져와 커스텀 UI를 구축할 수 있습니다.
- **전체 페이지 뷰** — App Store 스타일의 검색 가능한 전체 목록. 앱이 많은 개발자를 위한 기능.
- **자동 제외** — 현재 실행 중인 앱은 "다른 앱" 목록에서 자동으로 필터링됩니다.
- **오프라인 지원** — 2단계 캐싱 (메모리 + 디스크), 오프라인 시 만료된 캐시로 대응.
- **3가지 표시 스타일** — 컴팩트 목록, 리치 카드, 가로 스크롤 배너.
- **UIKit & AppKit** — UIKit/AppKit 프로젝트용 `MoreAppsViewController` 제공.
- **다국어** — 30개 이상의 언어 내장 지원.
- **iOS 15+** — iOS 15+ 및 macOS 12+ 지원.

## 설치

### Swift Package Manager

Xcode에서 MoreAppsKit 추가:

1. **File → Add Package Dependencies...**
2. 저장소 URL 입력:
   ```
   https://github.com/zhanggenlove/MoreAppsKit
   ```
3. **Up to Next Major Version** 선택, 시작 버전 `1.0.0`

또는 `Package.swift`에 추가:

```swift
dependencies: [
    .package(url: "https://github.com/zhanggenlove/MoreAppsKit", from: "1.0.0")
]
```

### CocoaPods

`Podfile`에 다음을 추가:

```ruby
pod 'MoreAppsKit', '~> 1.0'
```

그 다음 `pod install`을 실행하세요.

## 빠른 시작

### 1. 구성 (앱 시작 시 한 번)

```swift
import MoreAppsKit

@main
struct MyApp: App {
    init() {
        MoreAppsKit.configure(developerID: "당신의_개발자_ID")
    }
    // ...
}
```

### 2. 표시

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

이게 전부입니다. 뷰가 로딩, 캐싱, 에러 상태, 탭 처리를 자동으로 수행합니다.

## 표시 스타일

### 컴팩트 (기본값)

```swift
MoreAppsView()
MoreAppsView(style: .compact)
```

### 카드

```swift
MoreAppsView(style: .card)
```

### 배너

```swift
MoreAppsView(style: .banner)
```

## 표시 옵션

내장 뷰에 표시할 요소를 제어:

```swift
// 평점과 가격 숨김 (아이콘 + 이름만)
MoreAppsView(displayOptions: .minimal)

// 커스텀: 평점 숨김, 3개 앱만 표시하고 "모두 보기" 링크 표시
MoreAppsView(
    style: .card,
    displayOptions: .init(showRating: false, maxCount: 3)
)

// 모두 표시 (기본값)
MoreAppsView(displayOptions: .all)
```

## 현재 앱 + 평가 & 공유

상단에 현재 앱을 표시하고, 평가 및 공유 버튼 내장:

```swift
MoreAppsKit.configure(
    MoreAppsConfig(
        developerID: "1499619759",
        showCurrentApp: true
    )
)
```

App Store ID를 하드코딩할 필요 없음 — API에서 자동 감지됩니다.

## 데이터 전용 API

원시 데이터를 가져와 커스텀 UI를 구축:

```swift
let apps = try await MoreAppsKit.fetchApps()
for app in apps {
    print("\(app.name) — \(app.storeURL)")
}

// 현재 앱 자동 감지
if let current = await MoreAppsKit.currentApp() {
    print("현재 앱 ID: \(current.id)")
}

// 리뷰 요청 (App ID 하드코딩 불필요)
await MoreAppsKit.requestReview()
```

## 전체 페이지 뷰 (App Store 스타일)

앱이 많을 때 검색 가능한 전체 목록을 표시:

```swift
// 자동: maxCount를 설정하면 "모두 보기" 링크가 표시됨
MoreAppsView(
    style: .card,
    displayOptions: .init(maxCount: 3)
)

// 수동: 직접 내비게이션
NavigationLink("모든 앱") {
    MoreAppsFullView(apps: myApps)
}
```

## UIKit 통합

MoreAppsKit은 `MoreAppsViewController`를 제공합니다 — 바로 사용할 수 있는 `UIHostingController` 서브클래스입니다.

```swift
// Push
let vc = MoreAppsViewController(style: .card)
navigationController?.pushViewController(vc, animated: true)

// 모달 표시
let nav = MoreAppsViewController.wrapped(style: .compact)
present(nav, animated: true)

// 자식 컨트롤러로 임베드
let vc = MoreAppsViewController(style: .banner)
addChild(vc)
containerView.addSubview(vc.view)
vc.view.frame = containerView.bounds
vc.didMove(toParent: self)
```

## macOS (AppKit) 통합

macOS에서 `MoreAppsViewController`는 `NSHostingController`를 래핑합니다:

```swift
let vc = MoreAppsViewController(style: .card)
presentAsSheet(vc)
```

## 고급 구성

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

## 작동 원리

1. **iTunes Search API** — `itunes.apple.com/lookup?id=<devID>&entity=software&country=<cc>`로 앱을 가져옴
2. **로케일 해석** — 국가 코드는 `Locale.current`에서 가져와 이름, 설명, 가격의 현지화를 보장
3. **지역 폴백** — 로컬 지역에서 결과가 없으면 자동으로 "us"로 재시도
4. **스마트 캐싱** — 결과를 메모리와 디스크에 캐싱 (기본 24시간). 오프라인 시 만료된 캐시로 대응
5. **자동 필터** — 현재 앱 (`Bundle.main.bundleIdentifier`)은 "다른 앱" 목록에서 자동 제외
6. **App ID 자동 감지** — 현재 앱의 Store ID를 API에서 자동 가져와 하드코딩 없이 평가 및 공유 가능

## API 레퍼런스

| 타입 | 설명 |
|------|------|
| `MoreAppsKit.configure(developerID:)` | 개발자 ID로 빠른 설정 |
| `MoreAppsKit.configure(_:)` | `MoreAppsConfig`로 전체 설정 |
| `MoreAppsKit.fetchApps()` | 비동기 — 커스텀 UI용 `[MoreApp]` 반환 |
| `MoreAppsKit.currentApp()` | 비동기 — Store에서 현재 앱 감지 |
| `MoreAppsKit.requestReview()` | 비동기 — App Store 리뷰 프롬프트 실행 |
| `MoreAppsKit.clearCache()` | 캐시 데이터 수동 삭제 |
| `MoreAppsView` | 드롭인 SwiftUI 뷰 컴포넌트 |
| `MoreAppsFullView` | 전체 페이지 App Store 스타일 목록 |
| `MoreAppsViewController` | UIKit/AppKit 뷰 컨트롤러 (push, present, 임베드) |
| `MoreAppsFullViewController` | UIKit/AppKit 전체 페이지 목록 뷰 컨트롤러 |
| `MoreApp` | 단일 앱 데이터 모델 |
| `MoreAppsConfig` | 구성 옵션 |
| `DisplayOptions` | 표시 요소 제어 |
| `MoreAppsStyle` | `.compact` / `.card` / `.banner` |

## 요구 사항

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## 라이선스

MIT 라이선스. 자세한 내용은 [LICENSE](LICENSE)를 참조하세요.
