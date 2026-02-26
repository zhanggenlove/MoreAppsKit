import Foundation
#if canImport(StoreKit)
import StoreKit
#endif

/// Entry point for MoreAppsKit configuration and data access.
public enum MoreAppsKit {
    internal static var currentConfig: MoreAppsConfig?

    /// Configure MoreAppsKit with your Apple Developer ID.
    ///
    /// Call this once at app launch (e.g. in your `App.init()`).
    ///
    /// ```swift
    /// MoreAppsKit.configure(developerID: "1499619759")
    /// ```
    public static func configure(developerID: String) {
        currentConfig = MoreAppsConfig(developerID: developerID)
    }

    /// Configure MoreAppsKit with full options.
    ///
    /// ```swift
    /// MoreAppsKit.configure(
    ///     MoreAppsConfig(
    ///         developerID: "1499619759",
    ///         excludeBundleIds: ["com.example.beta"],
    ///         showCurrentApp: true,
    ///         displayOptions: .init(showRating: false)
    ///     )
    /// )
    /// ```
    public static func configure(_ config: MoreAppsConfig) {
        currentConfig = config
    }

    /// Clears the cached app data.
    public static func clearCache() {
        AppCache.shared.clear()
    }

    // MARK: - Data-Only API

    /// Fetches all apps by the configured developer, returning raw data.
    ///
    /// Use this when you want full control over the UI:
    /// ```swift
    /// let apps = try await MoreAppsKit.fetchApps()
    /// for app in apps {
    ///     print("\(app.name) — \(app.storeURL)")
    /// }
    /// ```
    public static func fetchApps() async throws -> [MoreApp] {
        guard let config = currentConfig else {
            throw MoreAppsError.notConfigured
        }

        let fetcher = AppStoreFetcher()
        let country = AppStoreFetcher.resolvedCountryCode

        if let cached = AppCache.shared.load(developerID: config.developerID, country: country, maxAge: config.cacheDuration) {
            return cached
        }

        let apps = try await fetcher.fetchApps(
            developerID: config.developerID,
            country: country,
            regionFallback: config.regionFallback
        )
        AppCache.shared.save(apps: apps, developerID: config.developerID, country: country)
        return apps
    }

    /// Discovers the current running app from the developer's App Store listing.
    /// Returns `nil` if the current app is not found (e.g. not yet published).
    public static func currentApp() async -> MoreApp? {
        guard let bundleId = Bundle.main.bundleIdentifier else { return nil }
        do {
            let apps = try await fetchApps()
            return apps.first { $0.bundleId == bundleId }
        } catch {
            return nil
        }
    }

    /// Requests an App Store review using the auto-discovered app ID.
    /// Falls back gracefully if StoreKit or the app is not available.
    @MainActor
    public static func requestReview() async {
        #if os(iOS)
        if #available(iOS 16, *) {
            if let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first {
                AppStore.requestReview(in: scene)
            }
        } else {
            if let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
        #elseif os(macOS)
        if #available(macOS 14, *) {
            if let controller = NSApplication.shared.keyWindow?.contentViewController {
                AppStore.requestReview(in: controller)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
        #endif
    }
}
