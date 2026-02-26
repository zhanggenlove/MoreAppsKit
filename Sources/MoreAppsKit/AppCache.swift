import Foundation

/// Two-tier cache (memory + disk) with configurable expiration.
final class AppCache: @unchecked Sendable {
    private var memoryCache: CacheEntry?
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.moreappskit.cache")

    static let shared = AppCache()
    private init() {}

    struct CacheEntry: Codable {
        let apps: [MoreApp]
        let timestamp: Date
        let country: String
        let developerID: String
    }

    private var cacheFileURL: URL? {
        fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("MoreAppsKit_cache.json")
    }

    // MARK: - Read

    func load(developerID: String, country: String, maxAge: TimeInterval) -> [MoreApp]? {
        queue.sync {
            if let entry = memoryCache, isValid(entry, developerID: developerID, country: country, maxAge: maxAge) {
                return entry.apps
            }

            if let entry = loadFromDisk(), isValid(entry, developerID: developerID, country: country, maxAge: maxAge) {
                memoryCache = entry
                return entry.apps
            }

            return nil
        }
    }

    /// Returns stale data regardless of expiration (for offline fallback).
    func loadStale(developerID: String) -> [MoreApp]? {
        queue.sync {
            if let entry = memoryCache, entry.developerID == developerID {
                return entry.apps
            }
            if let entry = loadFromDisk(), entry.developerID == developerID {
                return entry.apps
            }
            return nil
        }
    }

    // MARK: - Write

    func save(apps: [MoreApp], developerID: String, country: String) {
        let entry = CacheEntry(apps: apps, timestamp: Date(), country: country, developerID: developerID)
        queue.async { [weak self] in
            self?.memoryCache = entry
            self?.saveToDisk(entry)
        }
    }

    func clear() {
        queue.async { [weak self] in
            self?.memoryCache = nil
            if let url = self?.cacheFileURL {
                try? self?.fileManager.removeItem(at: url)
            }
        }
    }

    // MARK: - Disk I/O

    private func loadFromDisk() -> CacheEntry? {
        guard let url = cacheFileURL, fileManager.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(CacheEntry.self, from: data)
        } catch {
            return nil
        }
    }

    private func saveToDisk(_ entry: CacheEntry) {
        guard let url = cacheFileURL else { return }
        do {
            let data = try JSONEncoder().encode(entry)
            try data.write(to: url, options: .atomic)
        } catch {
            // Silent fail — cache is best-effort
        }
    }

    // MARK: - Validation

    private func isValid(_ entry: CacheEntry, developerID: String, country: String, maxAge: TimeInterval) -> Bool {
        entry.developerID == developerID
            && entry.country == country
            && Date().timeIntervalSince(entry.timestamp) < maxAge
    }
}
