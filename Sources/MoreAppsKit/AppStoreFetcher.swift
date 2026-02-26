import Foundation

/// Fetches developer apps from the iTunes Search API with locale-aware results.
final class AppStoreFetcher: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Resolves the App Store country code from the user's current locale.
    static var resolvedCountryCode: String {
        if #available(iOS 16, macOS 13, *) {
            return Locale.current.region?.identifier.lowercased() ?? "us"
        } else {
            return (Locale.current.regionCode ?? "US").lowercased()
        }
    }

    /// Fetches all apps by a developer, with optional region fallback.
    /// When `regionFallback` is true and the local region returns no apps,
    /// automatically retries with "us" (the most complete App Store region).
    func fetchApps(developerID: String, country: String? = nil, regionFallback: Bool = true) async throws -> [MoreApp] {
        let cc = country ?? Self.resolvedCountryCode
        let apps = try await fetchFromAPI(developerID: developerID, country: cc)

        if apps.isEmpty && regionFallback && cc != "us" {
            return try await fetchFromAPI(developerID: developerID, country: "us")
        }

        return apps
    }

    private func fetchFromAPI(developerID: String, country: String) async throws -> [MoreApp] {
        let urlString = "https://itunes.apple.com/lookup?id=\(developerID)&entity=software&country=\(country)"

        guard let url = URL(string: urlString) else {
            throw MoreAppsError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw MoreAppsError.networkError
        }

        let decoded = try JSONDecoder().decode(ITunesLookupResponse.self, from: data)

        return decoded.results.compactMap { $0.toMoreApp() }
    }
}

/// Errors specific to MoreAppsKit.
public enum MoreAppsError: LocalizedError, Equatable, Sendable {
    case notConfigured
    case invalidURL
    case networkError
    case noData

    public var errorDescription: String? {
        switch self {
        case .notConfigured: return "MoreAppsKit has not been configured. Call MoreAppsKit.configure() first."
        case .invalidURL:    return "Failed to construct the iTunes API URL."
        case .networkError:  return "Network request to the App Store failed."
        case .noData:        return "No app data available."
        }
    }
}
