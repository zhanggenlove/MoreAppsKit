#if canImport(UIKit)
import UIKit
import SwiftUI

/// A UIKit-friendly view controller that wraps `MoreAppsView`.
///
/// **Push onto a navigation stack:**
/// ```swift
/// let vc = MoreAppsViewController(style: .card)
/// navigationController?.pushViewController(vc, animated: true)
/// ```
///
/// **Present modally (auto-wraps in NavigationController):**
/// ```swift
/// let vc = MoreAppsViewController.wrapped(style: .compact)
/// present(vc, animated: true)
/// ```
///
/// **Embed as a child:**
/// ```swift
/// let vc = MoreAppsViewController(style: .banner)
/// addChild(vc)
/// view.addSubview(vc.view)
/// vc.didMove(toParent: self)
/// ```
@available(iOS 15.0, *)
public final class MoreAppsViewController: UIHostingController<AnyView> {

    /// Creates a view controller displaying the developer's other apps.
    ///
    /// When using `push`, the view embeds directly without extra navigation chrome.
    /// When using `wrapped()` for modal presentation, navigation is included automatically.
    ///
    /// - Parameters:
    ///   - style: Layout style (`.compact`, `.card`, `.banner`).
    ///   - headerTitle: Section header title. Defaults to the localized "More Apps".
    ///   - displayOptions: Controls which elements (rating, price, description) are visible.
    ///   - wrapInNavigation: Whether to wrap content in a NavigationView. Defaults to `false`.
    public init(
        style: MoreAppsStyle = .compact,
        headerTitle: String? = nil,
        displayOptions: DisplayOptions? = nil,
        wrapInNavigation: Bool = false
    ) {
        let moreAppsView = Form {
            MoreAppsView(
                style: style,
                headerTitle: headerTitle,
                displayOptions: displayOptions
            )
        }
        if wrapInNavigation {
            let content = NavigationView { moreAppsView }
            super.init(rootView: AnyView(content))
        } else {
            super.init(rootView: AnyView(moreAppsView))
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: AnyView(EmptyView()))
    }

    /// Returns a `UINavigationController` wrapping this view controller, ready for modal presentation.
    public static func wrapped(
        style: MoreAppsStyle = .compact,
        headerTitle: String? = nil,
        displayOptions: DisplayOptions? = nil
    ) -> UINavigationController {
        let vc = MoreAppsViewController(
            style: style,
            headerTitle: headerTitle,
            displayOptions: displayOptions,
            wrapInNavigation: true
        )
        return UINavigationController(rootViewController: vc)
    }
}

/// A UIKit-friendly view controller that shows the full App Store-style list of all apps.
///
/// ```swift
/// let apps: [MoreApp] = ... // from MoreAppsKit.fetchApps()
/// let vc = MoreAppsFullViewController(apps: apps)
/// navigationController?.pushViewController(vc, animated: true)
/// ```
@available(iOS 15.0, *)
public final class MoreAppsFullViewController: UIHostingController<AnyView> {

    public init(
        apps: [MoreApp],
        displayOptions: DisplayOptions = .all,
        headerTitle: String? = nil,
        wrapInNavigation: Bool = false
    ) {
        let fullView = MoreAppsFullView(
            apps: apps,
            displayOptions: displayOptions,
            headerTitle: headerTitle
        )
        if wrapInNavigation {
            let content = NavigationView { fullView }
            super.init(rootView: AnyView(content))
        } else {
            super.init(rootView: AnyView(fullView))
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: AnyView(EmptyView()))
    }

    public static func wrapped(
        apps: [MoreApp],
        displayOptions: DisplayOptions = .all,
        headerTitle: String? = nil
    ) -> UINavigationController {
        let vc = MoreAppsFullViewController(
            apps: apps,
            displayOptions: displayOptions,
            headerTitle: headerTitle,
            wrapInNavigation: true
        )
        return UINavigationController(rootViewController: vc)
    }
}

#elseif canImport(AppKit)
import AppKit
import SwiftUI

/// A macOS-friendly view controller that wraps `MoreAppsView`.
///
/// ```swift
/// let vc = MoreAppsViewController(style: .card)
/// presentAsSheet(vc)
/// ```
@available(macOS 12.0, *)
public final class MoreAppsViewController: NSHostingController<AnyView> {

    public init(
        style: MoreAppsStyle = .compact,
        headerTitle: String? = nil,
        displayOptions: DisplayOptions? = nil,
        wrapInNavigation: Bool = true
    ) {
        let moreAppsView = Form {
            MoreAppsView(
                style: style,
                headerTitle: headerTitle,
                displayOptions: displayOptions
            )
        }
        if wrapInNavigation {
            let content = NavigationView { moreAppsView }
            super.init(rootView: AnyView(content))
        } else {
            super.init(rootView: AnyView(moreAppsView))
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder: NSCoder) {
        super.init(coder: coder, rootView: AnyView(EmptyView()))
    }
}

/// A macOS-friendly view controller showing the full list of apps.
@available(macOS 12.0, *)
public final class MoreAppsFullViewController: NSHostingController<AnyView> {

    public init(
        apps: [MoreApp],
        displayOptions: DisplayOptions = .all,
        headerTitle: String? = nil,
        wrapInNavigation: Bool = true
    ) {
        let fullView = MoreAppsFullView(
            apps: apps,
            displayOptions: displayOptions,
            headerTitle: headerTitle
        )
        if wrapInNavigation {
            let content = NavigationView { fullView }
            super.init(rootView: AnyView(content))
        } else {
            super.init(rootView: AnyView(fullView))
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder: NSCoder) {
        super.init(coder: coder, rootView: AnyView(EmptyView()))
    }
}
#endif
