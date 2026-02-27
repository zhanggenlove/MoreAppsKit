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

    private static let maxRetries = 3
    private static let retryDelays: [UInt64] = [2, 4, 8]

    private var didLoad = false
    private var retryCount = 0
    private var retryTask: Task<Void, Never>?

    func loadIfNeeded() {
        guard !didLoad, !isLoading else { return }
        retryCount = 0
        performLoad()
    }

    func retry() {
        retryTask?.cancel()
        retryCount = 0
        didLoad = false
        hasError = false
        performLoad()
    }

    private func performLoad() {
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

        retryTask = Task {
            do {
                let result = try await fetcher.fetchApps(
                    developerID: config.developerID,
                    country: country,
                    regionFallback: config.regionFallback
                )
                guard !Task.isCancelled else { return }
                cache.save(apps: result, developerID: config.developerID, country: country)
                partition(result, config: config)
                self.isLoading = false
                self.didLoad = true
            } catch {
                guard !Task.isCancelled else { return }

                if let stale = cache.loadStale(developerID: config.developerID) {
                    partition(stale, config: config)
                    self.isLoading = false
                    self.didLoad = true
                    return
                }

                if retryCount < Self.maxRetries {
                    let delay = Self.retryDelays[min(retryCount, Self.retryDelays.count - 1)]
                    retryCount += 1
                    try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
                    guard !Task.isCancelled else { return }
                    performLoad()
                } else {
                    self.hasError = true
                    self.isLoading = false
                }
            }
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
