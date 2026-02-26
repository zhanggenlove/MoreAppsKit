import SwiftUI

#if canImport(StoreKit) && os(iOS)
import StoreKit

@MainActor
final class StoreProductCoordinator: NSObject, SKStoreProductViewControllerDelegate, ObservableObject {
    @Published var isLoading = false
    private var storeVC: SKStoreProductViewController?

    func present(appID: Int) {
        guard !isLoading else { return }
        isLoading = true

        let store = SKStoreProductViewController()
        store.delegate = self
        self.storeVC = store

        store.loadProduct(withParameters: [
            SKStoreProductParameterITunesItemIdentifier: appID
        ]) { [weak self] success, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if success, let presenter = self.topViewController() {
                    presenter.present(store, animated: true) {
                        self.isLoading = false
                    }
                } else {
                    self.isLoading = false
                    self.storeVC = nil
                }
            }
        }
    }

    nonisolated func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        DispatchQueue.main.async {
            viewController.dismiss(animated: true)
        }
    }

    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.keyWindow?.rootViewController else {
            return nil
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

struct StoreProductModifier: ViewModifier {
    @Binding var selectedApp: MoreApp?
    @StateObject private var coordinator = StoreProductCoordinator()

    func body(content: Content) -> some View {
        content
            .onChange(of: selectedApp) { _, newValue in
                if let app = newValue {
                    coordinator.present(appID: app.id)
                    selectedApp = nil
                }
            }
    }
}

extension View {
    func storeProduct(selectedApp: Binding<MoreApp?>) -> some View {
        modifier(StoreProductModifier(selectedApp: selectedApp))
    }
}
#endif
