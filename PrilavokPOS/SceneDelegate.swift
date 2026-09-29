import UIKit

/// Scene-based lifecycle required by current iPadOS versions.
/// Keep a single scene because M POS is designed as a single-window POS.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = POSViewController()
        self.window = window
        window.makeKeyAndVisible()
    }
}
