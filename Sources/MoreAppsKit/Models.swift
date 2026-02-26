import Foundation

/// The platform an app runs on.
public enum AppPlatform: String, Codable, Sendable {
    case iOS = "software"
    case macOS = "mac-software"
    case unknown = "unknown"
}

/// A single app retrieved from the App Store.
public struct MoreApp: Identifiable, Hashable, Codable, Sendable {
    public let id: Int
    public let name: String
    public let description: String
    public let iconURL: URL
    public let storeURL: URL
    public let bundleId: String
    public let price: String
    public let genres: [String]
    public let averageRating: Double?
    public let ratingCount: Int?
    public let platform: AppPlatform

    /// Whether this app is the currently running app.
    public var isCurrentApp: Bool {
        bundleId == Bundle.main.bundleIdentifier
    }

    /// The App Store review URL for this app.
    public var reviewURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(id)?action=write-review")
    }

    /// A shareable App Store URL (without tracking parameters).
    public var shareURL: URL {
        URL(string: "https://apps.apple.com/app/id\(id)") ?? storeURL
    }
}

// MARK: - Display Options

/// Controls which elements are visible in the built-in views.
public struct DisplayOptions: Sendable {
    public let showRating: Bool
    public let showPrice: Bool
    public let showDescription: Bool
    public let maxCount: Int?

    public init(
        showRating: Bool = true,
        showPrice: Bool = true,
        showDescription: Bool = true,
        maxCount: Int? = nil
    ) {
        self.showRating = showRating
        self.showPrice = showPrice
        self.showDescription = showDescription
        self.maxCount = maxCount
    }

    /// Shows everything, no limit.
    public static let all = DisplayOptions()

    /// Minimal: name + icon only.
    public static let minimal = DisplayOptions(showRating: false, showPrice: false, showDescription: false)
}

// MARK: - Display Style

/// Display style for the apps list.
public enum MoreAppsStyle: Sendable {
    /// Single-line rows with icon, name, and chevron. Ideal for Form/List.
    case compact
    /// Rich cards with large icon, description, and "GET" button.
    case card
    /// Horizontal scrolling banner. Ideal for embedding in a home screen.
    case banner
}

// MARK: - Configuration

/// Configuration for MoreAppsKit.
public struct MoreAppsConfig: Sendable {
    public let developerID: String
    public let excludeBundleIds: Set<String>
    public let platformFilter: PlatformFilter
    public let cacheDuration: TimeInterval
    public let regionFallback: Bool
    public let showCurrentApp: Bool
    public let displayOptions: DisplayOptions
    public let onAppTapped: (@Sendable (MoreApp) -> Void)?

    public enum PlatformFilter: Sendable {
        case all
        case iOS
        case macOS
    }

    public init(
        developerID: String,
        excludeBundleIds: Set<String> = [],
        platformFilter: PlatformFilter = .all,
        cacheDuration: TimeInterval = 86400,
        regionFallback: Bool = true,
        showCurrentApp: Bool = false,
        displayOptions: DisplayOptions = .all,
        onAppTapped: (@Sendable (MoreApp) -> Void)? = nil
    ) {
        self.developerID = developerID
        self.excludeBundleIds = excludeBundleIds
        self.platformFilter = platformFilter
        self.cacheDuration = cacheDuration
        self.regionFallback = regionFallback
        self.showCurrentApp = showCurrentApp
        self.displayOptions = displayOptions
        self.onAppTapped = onAppTapped
    }
}

// MARK: - iTunes API Response

struct ITunesLookupResponse: Codable {
    let resultCount: Int
    let results: [ITunesResult]
}

struct ITunesResult: Codable {
    let wrapperType: String?
    let kind: String?
    let trackId: Int?
    let trackName: String?
    let bundleId: String?
    let artworkUrl512: String?
    let artworkUrl100: String?
    let trackViewUrl: String?
    let formattedPrice: String?
    let description: String?
    let genres: [String]?
    let averageUserRating: Double?
    let userRatingCount: Int?

    var isSoftware: Bool {
        wrapperType == "software"
    }

    func toMoreApp() -> MoreApp? {
        guard isSoftware,
              let trackId,
              let trackName,
              let bundleId,
              let iconStr = artworkUrl512 ?? artworkUrl100,
              let iconURL = URL(string: iconStr),
              let storeStr = trackViewUrl,
              let storeURL = URL(string: storeStr)
        else { return nil }

        let platform = AppPlatform(rawValue: kind ?? "") ?? .unknown

        return MoreApp(
            id: trackId,
            name: trackName,
            description: description ?? "",
            iconURL: iconURL,
            storeURL: storeURL,
            bundleId: bundleId,
            price: formattedPrice ?? L10n.free,
            genres: genres ?? [],
            averageRating: averageUserRating,
            ratingCount: userRatingCount,
            platform: platform
        )
    }
}
