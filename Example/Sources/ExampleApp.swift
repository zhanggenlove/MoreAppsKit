import SwiftUI
import MoreAppsKit

@main
struct ExampleApp: App {
    init() {
        MoreAppsKit.configure(
            MoreAppsConfig(
                developerID: "281956209",
                showCurrentApp: true,
                displayOptions: .init(maxCount: 5)
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ExampleTabView()
            }
        }
    }
}

struct ExampleTabView: View {
    var body: some View {
        Form {
            Section("Display Styles") {
                NavigationLink("Compact Style") { CompactExample() }
                NavigationLink("Card Style") { CardExample() }
                NavigationLink("Banner Style") { BannerExample() }
            }

            Section("Options") {
                NavigationLink("No Rating") { NoRatingExample() }
                NavigationLink("Minimal (Icon + Name)") { MinimalExample() }
                NavigationLink("Custom UI (Data API)") { CustomUIExample() }
            }
        }
        .navigationTitle("MoreAppsKit Demo")
    }
}

// MARK: - Compact

struct CompactExample: View {
    var body: some View {
        Form {
            MoreAppsView(style: .compact)
        }
        .navigationTitle("Compact")
    }
}

// MARK: - Card

struct CardExample: View {
    var body: some View {
        Form {
            MoreAppsView(style: .card)
        }
        .navigationTitle("Card")
    }
}

// MARK: - Banner

struct BannerExample: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                MoreAppsView(style: .banner)
            }
            .padding(.vertical)
        }
        .navigationTitle("Banner")
    }
}

// MARK: - No Rating

struct NoRatingExample: View {
    var body: some View {
        Form {
            MoreAppsView(
                style: .card,
                displayOptions: .init(showRating: false)
            )
        }
        .navigationTitle("No Rating")
    }
}

// MARK: - Minimal

struct MinimalExample: View {
    var body: some View {
        Form {
            MoreAppsView(displayOptions: .minimal)
        }
        .navigationTitle("Minimal")
    }
}

// MARK: - Custom UI with Data API

struct CustomUIExample: View {
    @State private var apps: [MoreApp] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if apps.isEmpty {
                if #available(iOS 17, macOS 14, *) {
                    ContentUnavailableView(
                        "No Apps Found",
                        systemImage: "app.dashed",
                        description: Text("Could not load apps from the App Store.")
                    )
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "app.dashed")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No Apps Found")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                List(apps) { app in
                    HStack(spacing: 12) {
                        AsyncImage(url: app.iconURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.quaternary)
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name).font(.headline)
                            Text(app.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Link("Open", destination: app.storeURL)
                            .font(.caption.weight(.semibold))
                    }
                }
            }
        }
        .navigationTitle("Custom UI")
        .task {
            apps = (try? await MoreAppsKit.fetchApps()) ?? []
            isLoading = false
        }
    }
}
