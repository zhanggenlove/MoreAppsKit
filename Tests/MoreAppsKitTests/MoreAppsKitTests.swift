import XCTest
@testable import MoreAppsKit

final class MoreAppsKitTests: XCTestCase {

    override func tearDown() {
        MoreAppsKit.currentConfig = nil
        MoreAppsKit.clearCache()
        super.tearDown()
    }

    func testConfigureSetsDeveloperID() {
        MoreAppsKit.configure(developerID: "1499619759")
        XCTAssertEqual(MoreAppsKit.currentConfig?.developerID, "1499619759")
    }

    func testConfigureWithFullConfig() {
        let config = MoreAppsConfig(
            developerID: "123456",
            excludeBundleIds: ["com.test.app"],
            platformFilter: .iOS,
            cacheDuration: 3600,
            regionFallback: false,
            showCurrentApp: true,
            displayOptions: .init(showRating: false, showPrice: false)
        )
        MoreAppsKit.configure(config)
        XCTAssertEqual(MoreAppsKit.currentConfig?.developerID, "123456")
        XCTAssertTrue(MoreAppsKit.currentConfig?.excludeBundleIds.contains("com.test.app") ?? false)
        XCTAssertEqual(MoreAppsKit.currentConfig?.cacheDuration, 3600)
        XCTAssertFalse(MoreAppsKit.currentConfig?.regionFallback ?? true)
        XCTAssertTrue(MoreAppsKit.currentConfig?.showCurrentApp ?? false)
        XCTAssertFalse(MoreAppsKit.currentConfig?.displayOptions.showRating ?? true)
    }

    func testITunesResultParsing() throws {
        let json = """
        {
            "resultCount": 2,
            "results": [
                {
                    "wrapperType": "artist",
                    "artistType": "Software Artist",
                    "artistName": "Test Developer",
                    "artistId": 12345
                },
                {
                    "wrapperType": "software",
                    "kind": "software",
                    "trackId": 999,
                    "trackName": "Test App",
                    "bundleId": "com.test.app",
                    "artworkUrl512": "https://example.com/icon.png",
                    "trackViewUrl": "https://apps.apple.com/app/id999",
                    "formattedPrice": "Free",
                    "description": "A test app.",
                    "genres": ["Utilities"],
                    "averageUserRating": 4.5,
                    "userRatingCount": 100
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ITunesLookupResponse.self, from: json)
        XCTAssertEqual(response.resultCount, 2)

        let apps = response.results.compactMap { $0.toMoreApp() }
        XCTAssertEqual(apps.count, 1)
        XCTAssertEqual(apps.first?.name, "Test App")
        XCTAssertEqual(apps.first?.bundleId, "com.test.app")
        XCTAssertEqual(apps.first?.price, "Free")
        XCTAssertEqual(apps.first?.averageRating, 4.5)
        XCTAssertEqual(apps.first?.platform, .iOS)
    }

    func testPlatformParsing() throws {
        let json = """
        {
            "resultCount": 3,
            "results": [
                { "wrapperType": "artist", "artistId": 1 },
                { "wrapperType": "software", "kind": "software", "trackId": 100, "trackName": "iOS App",
                  "bundleId": "com.test.ios", "artworkUrl100": "https://example.com/icon.png",
                  "trackViewUrl": "https://apps.apple.com/app/id100" },
                { "wrapperType": "software", "kind": "mac-software", "trackId": 200, "trackName": "Mac App",
                  "bundleId": "com.test.mac", "artworkUrl100": "https://example.com/icon.png",
                  "trackViewUrl": "https://apps.apple.com/app/id200" }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ITunesLookupResponse.self, from: json)
        let apps = response.results.compactMap { $0.toMoreApp() }
        XCTAssertEqual(apps.count, 2)
        XCTAssertEqual(apps[0].platform, .iOS)
        XCTAssertEqual(apps[1].platform, .macOS)
    }

    func testMoreAppProperties() {
        let app = MoreApp(
            id: 123, name: "Test", description: "desc",
            iconURL: URL(string: "https://example.com/icon.png")!,
            storeURL: URL(string: "https://apps.apple.com/app/id123")!,
            bundleId: "com.test", price: "Free", genres: ["Utilities"],
            averageRating: 4.0, ratingCount: 10, platform: .iOS
        )
        XCTAssertNotNil(app.reviewURL)
        XCTAssertEqual(app.shareURL.absoluteString, "https://apps.apple.com/app/id123")
        XCTAssertFalse(app.isCurrentApp)
        XCTAssertEqual(app.platform, .iOS)
    }

    func testDisplayOptionsPresets() {
        let all = DisplayOptions.all
        XCTAssertTrue(all.showRating)
        XCTAssertTrue(all.showPrice)
        XCTAssertTrue(all.showDescription)
        XCTAssertNil(all.maxCount)

        let minimal = DisplayOptions.minimal
        XCTAssertFalse(minimal.showRating)
        XCTAssertFalse(minimal.showPrice)
        XCTAssertFalse(minimal.showDescription)
    }

    func testCountryCodeResolution() {
        let code = AppStoreFetcher.resolvedCountryCode
        XCTAssertFalse(code.isEmpty)
    }

    func testCacheWriteAndRead() {
        let cache = AppCache.shared
        let app = MoreApp(
            id: 1, name: "Test", description: "desc",
            iconURL: URL(string: "https://example.com/icon.png")!,
            storeURL: URL(string: "https://apps.apple.com/app/id1")!,
            bundleId: "com.test", price: "Free", genres: ["Utilities"],
            averageRating: 4.0, ratingCount: 10, platform: .iOS
        )
        cache.save(apps: [app], developerID: "dev1", country: "us")

        let loaded = cache.load(developerID: "dev1", country: "us", maxAge: 3600)
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?.first?.name, "Test")

        let wrongCountry = cache.load(developerID: "dev1", country: "cn", maxAge: 3600)
        XCTAssertNil(wrongCountry)

        let stale = cache.loadStale(developerID: "dev1")
        XCTAssertNotNil(stale)
    }

    func testFetchAppsWithoutConfig() async {
        MoreAppsKit.currentConfig = nil
        do {
            _ = try await MoreAppsKit.fetchApps()
            XCTFail("Should throw notConfigured error")
        } catch let error as MoreAppsError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

