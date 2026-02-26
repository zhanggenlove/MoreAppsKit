import SwiftUI

#if canImport(StoreKit) && os(iOS)
import StoreKit

/// Presents an App Store product page inside the app using SKStoreProductViewController.
struct StoreProductPresenter: UIViewControllerRepresentable {
    let appID: Int
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let host = UIViewController()
        host.view.backgroundColor = .clear
        return host
    }

    func updateUIViewController(_ host: UIViewController, context: Context) {
        guard host.presentedViewController == nil,
              !context.coordinator.isPresenting else { return }
        context.coordinator.isPresenting = true

        let store = SKStoreProductViewController()
        store.delegate = context.coordinator

        store.loadProduct(withParameters: [
            SKStoreProductParameterITunesItemIdentifier: appID
        ]) { success, _ in
            DispatchQueue.main.async {
                if success {
                    host.present(store, animated: true)
                } else {
                    context.coordinator.isPresenting = false
                    onDismiss()
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    final class Coordinator: NSObject, SKStoreProductViewControllerDelegate {
        let onDismiss: () -> Void
        var isPresenting = false

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            viewController.dismiss(animated: true) { [weak self] in
                self?.isPresenting = false
                self?.onDismiss()
            }
        }
    }
}

/// A ViewModifier that presents SKStoreProductViewController as a fullScreenCover.
struct StoreProductModifier: ViewModifier {
    @Binding var selectedApp: MoreApp?

    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: $selectedApp) { app in
                StoreProductPresenter(appID: app.id) {
                    selectedApp = nil
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    func storeProduct(selectedApp: Binding<MoreApp?>) -> some View {
        modifier(StoreProductModifier(selectedApp: selectedApp))
    }
}
#endif
