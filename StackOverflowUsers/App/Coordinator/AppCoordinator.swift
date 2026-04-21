import UIKit

@MainActor
final class AppCoordinator: Coordinator {

    private let window: UIWindow
    private let navigationController = UINavigationController()

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .systemBackground
        rootViewController.title = "StackOverflow Users"

        navigationController.setViewControllers([rootViewController], animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
