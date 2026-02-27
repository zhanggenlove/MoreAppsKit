import SwiftUI
#if canImport(StoreKit)
import StoreKit
#endif

// MARK: - Main Entry View

/// A ready-to-use SwiftUI view that displays the developer's other apps.
///
/// ```swift
/// Form {
///     MoreAppsView()
///     MoreAppsView(style: .card, displayOptions: .init(showRating: false))
///     MoreAppsView(style: .compact, displayOptions: .init(maxCount: 3))
/// }
/// ```
public struct MoreAppsView: View {
    private let style: MoreAppsStyle
    private let headerTitle: String
    private let displayOptions: DisplayOptions
    @StateObject private var viewModel = MoreAppsViewModel()
    @State private var selectedApp: MoreApp?

    public init(
        style: MoreAppsStyle = .compact,
        headerTitle: String? = nil,
        displayOptions: DisplayOptions? = nil
    ) {
        self.style = style
        self.headerTitle = headerTitle ?? L10n.moreApps
        self.displayOptions = displayOptions ?? MoreAppsKit.currentConfig?.displayOptions ?? .all
    }

    public var body: some View {
        bodyContent
            .task(id: "load") { viewModel.loadIfNeeded() }
            #if os(iOS)
            .storeProduct(selectedApp: $selectedApp)
            #endif
    }

    @ViewBuilder
    private var bodyContent: some View {
        if viewModel.isLoading {
            loadingSection
        } else if !viewModel.otherApps.isEmpty || viewModel.currentApp != nil {
            mainContent
        } else if viewModel.hasError {
            errorSection
        } else {
            loadingSection
        }
    }

    private var loadingSection: some View {
        Section(header: Text(headerTitle)) {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    private var errorSection: some View {
        Section(header: Text(headerTitle)) {
            VStack(spacing: 10) {
                Text(L10n.loadFailed)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button {
                    viewModel.retry()
                } label: {
                    Label(L10n.retry, systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if let current = viewModel.currentApp {
            currentAppSection(current)
        }

        switch style {
        case .compact:
            compactSection
        case .card:
            cardSection
        case .banner:
            bannerSection
        }
    }

    // MARK: - Current App

    @ViewBuilder
    private func currentAppSection(_ app: MoreApp) -> some View {
        Section {
            CurrentAppRow(app: app, displayOptions: displayOptions)
        }
    }

    // MARK: - Compact

    private var compactSection: some View {
        Section(header: Text(headerTitle)) {
            ForEach(limitedApps) { app in
                CompactAppRow(app: app, displayOptions: displayOptions) {
                    handleTap(app)
                }
            }
            seeAllLink
        }
    }

    // MARK: - Card

    private var cardSection: some View {
        Section(header: Text(headerTitle)) {
            ForEach(limitedApps) { app in
                CardAppRow(app: app, displayOptions: displayOptions) {
                    handleTap(app)
                }
            }
            seeAllLink
        }
    }

    // MARK: - Banner

    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(headerTitle)
                    .font(.headline)
                Spacer()
                if shouldShowSeeAll {
                    NavigationLink(destination: MoreAppsFullView(
                        apps: viewModel.otherApps,
                        displayOptions: displayOptions,
                        headerTitle: headerTitle
                    )) {
                        Text(L10n.seeAll)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(limitedApps) { app in
                        BannerAppCard(app: app, displayOptions: displayOptions) {
                            handleTap(app)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Helpers

    private var limitedApps: [MoreApp] {
        if let max = displayOptions.maxCount {
            return Array(viewModel.otherApps.prefix(max))
        }
        return viewModel.otherApps
    }

    private var shouldShowSeeAll: Bool {
        guard let max = displayOptions.maxCount else { return false }
        return viewModel.otherApps.count > max
    }

    @ViewBuilder
    private var seeAllLink: some View {
        if shouldShowSeeAll {
            NavigationLink(destination: MoreAppsFullView(
                apps: viewModel.otherApps,
                displayOptions: displayOptions,
                headerTitle: headerTitle
            )) {
                HStack {
                    Text(L10n.seeAll)
                    Spacer()
                    Text("\(viewModel.otherApps.count)")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func handleTap(_ app: MoreApp) {
        MoreAppsKit.currentConfig?.onAppTapped?(app)
        #if os(iOS)
        selectedApp = app
        #else
        openURL(app.storeURL)
        #endif
    }

    #if !os(iOS)
    private func openURL(_ url: URL) {
        #if canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
    #endif
}

// MARK: - Current App Row

private struct CurrentAppRow: View {
    let app: MoreApp
    let displayOptions: DisplayOptions

    var body: some View {
        HStack(spacing: 14) {
            AppIconView(url: app.iconURL, size: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if displayOptions.showDescription && !app.description.isEmpty {
                    Text(app.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if displayOptions.showRating, let rating = app.averageRating {
                    StarRatingView(rating: rating)
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                Button {
                    Task { await MoreAppsKit.requestReview() }
                } label: {
                    Text(L10n.rate)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if #available(iOS 16, macOS 13, *) {
                    ShareLink(item: app.shareURL) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        #if os(iOS)
                        let av = UIActivityViewController(activityItems: [app.shareURL], applicationActivities: nil)
                        UIApplication.shared.connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .first?.windows.first?.rootViewController?
                            .present(av, animated: true)
                        #endif
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Compact Row

private struct CompactAppRow: View {
    let app: MoreApp
    let displayOptions: DisplayOptions
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AppIconView(url: app.iconURL, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    if displayOptions.showDescription {
                        Text(app.genres.first ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if displayOptions.showPrice {
                    PriceBadge(price: app.price)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card Row

private struct CardAppRow: View {
    let app: MoreApp
    let displayOptions: DisplayOptions
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                AppIconView(url: app.iconURL, size: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if displayOptions.showDescription && !app.description.isEmpty {
                        Text(app.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 6) {
                        if displayOptions.showRating, let rating = app.averageRating {
                            StarRatingView(rating: rating)
                        }
                        if displayOptions.showPrice {
                            PriceBadge(price: app.price, small: true)
                        }
                    }
                    .padding(.top, 2)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Banner Card

private struct BannerAppCard: View {
    let app: MoreApp
    let displayOptions: DisplayOptions
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                AppIconView(url: app.iconURL, size: 56)

                Text(app.name)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(width: 80)

                if displayOptions.showPrice {
                    PriceBadge(price: app.price, small: true)
                }
            }
            .frame(width: 90)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Full Page (App Store Style)

/// A full-page view showing all apps in an App Store-inspired layout.
public struct MoreAppsFullView: View {
    let apps: [MoreApp]
    let displayOptions: DisplayOptions
    let headerTitle: String

    @State private var searchText = ""
    @State private var selectedApp: MoreApp?

    public init(apps: [MoreApp], displayOptions: DisplayOptions = .all, headerTitle: String? = nil) {
        self.apps = apps
        self.displayOptions = displayOptions
        self.headerTitle = headerTitle ?? L10n.moreApps
    }

    private var filteredApps: [MoreApp] {
        if searchText.isEmpty { return apps }
        let query = searchText.lowercased()
        return apps.filter {
            $0.name.lowercased().contains(query)
            || $0.description.lowercased().contains(query)
            || $0.genres.contains { $0.lowercased().contains(query) }
        }
    }

    public var body: some View {
        List {
            ForEach(filteredApps) { app in
                FullPageAppRow(app: app, displayOptions: displayOptions) {
                    MoreAppsKit.currentConfig?.onAppTapped?(app)
                    #if os(iOS)
                    selectedApp = app
                    #elseif canImport(AppKit)
                    NSWorkspace.shared.open(app.storeURL)
                    #endif
                }
            }
        }
        .navigationTitle(headerTitle)
        .searchable(text: $searchText, prompt: Text(L10n.searchApps))
        #if os(iOS)
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.large)
        .storeProduct(selectedApp: $selectedApp)
        #endif
    }
}

private struct FullPageAppRow: View {
    let app: MoreApp
    let displayOptions: DisplayOptions
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                AppIconView(url: app.iconURL, size: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if displayOptions.showDescription && !app.description.isEmpty {
                        Text(app.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 6) {
                        if displayOptions.showRating, let rating = app.averageRating {
                            StarRatingView(rating: rating)
                        }
                        if let count = app.ratingCount, displayOptions.showRating {
                            Text("(\(count))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer(minLength: 0)

                if displayOptions.showPrice {
                    PriceBadge(price: app.price)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared Components

struct AppIconView: View {
    let url: URL
    let size: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                iconPlaceholder
            case .empty:
                iconPlaceholder
                    .overlay(ProgressView().scaleEffect(0.6))
            @unknown default:
                iconPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }

    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
            .fill(Color.gray.opacity(0.15))
    }
}

private struct StarRatingView: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundColor(.orange)
            Text(String(format: "%.1f", rating))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private struct PriceBadge: View {
    let price: String
    var small: Bool = false

    var body: some View {
        Text(price)
            .font(small ? .caption2.weight(.semibold) : .caption.weight(.semibold))
            .padding(.horizontal, small ? 8 : 12)
            .padding(.vertical, small ? 3 : 5)
            .background(Color.accentColor.opacity(0.12))
            .foregroundColor(.accentColor)
            .clipShape(Capsule())
    }
}
