import SwiftUI

@MainActor
final class MoreAppsViewModel: ObservableObject {
    @Published var currentApp: MoreApp?
    @Published var otherApps: [MoreApp] = []
    @Published var isLoading = false
    @Published var hasError = false

    /// All apps including current app (for full-page view).
    var allApps: [MoreApp] {
        if let current = currentApp {
            return [current] + otherApps
        }
        return otherApps
    }

    private let fetcher = AppStoreFetcher()
    private let cache = AppCache.shared

    private var didLoad = false

    func loadIfNeeded() {
        guard !didLoad, !isLoading else { return }

        guard let config = MoreAppsKit.currentConfig else {
            hasError = true
            return
        }

        let country = AppStoreFetcher.resolvedCountryCode

        if let cached = cache.load(developerID: config.developerID, country: country, maxAge: config.cacheDuration) {
            partition(cached, config: config)
            didLoad = true
            return
        }

        isLoading = true
        hasError = false

        Task {
            do {
                let result = try await fetcher.fetchApps(
                    developerID: config.developerID,
                    country: country,
                    regionFallback: config.regionFallback
                )
                cache.save(apps: result, developerID: config.developerID, country: country)
                partition(result, config: config)
            } catch {
                if let stale = cache.loadStale(developerID: config.developerID) {
                    partition(stale, config: config)
                } else {
                    self.hasError = true
                }
            }
            self.isLoading = false
            self.didLoad = true
        }
    }

    private func partition(_ apps: [MoreApp], config: MoreAppsConfig) {
        let currentBundleId = Bundle.main.bundleIdentifier ?? ""

        let platformFiltered = apps.filter { app in
            switch config.platformFilter {
            case .all:  return true
            case .iOS:  return app.platform == .iOS
            case .macOS: return app.platform == .macOS
            }
        }

        if config.showCurrentApp {
            self.currentApp = platformFiltered.first { $0.bundleId == currentBundleId }
        }

        self.otherApps = platformFiltered.filter { app in
            if app.bundleId == currentBundleId { return false }
            if config.excludeBundleIds.contains(app.bundleId) { return false }
            return true
        }
    }
}
