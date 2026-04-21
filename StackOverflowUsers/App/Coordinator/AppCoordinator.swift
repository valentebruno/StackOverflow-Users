import UIKit

// MARK: - AppCoordinator

@MainActor
final class AppCoordinator: Coordinator {

    private let window: UIWindow
    private let navigationController = UINavigationController()

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let userService      = UserService()
        let followRepository = UserDefaultsFollowRepository()
        let userCache        = FileUserCache()
        let imageLoader      = ImageLoader.shared

        let viewModel = UserListViewModel(
            userService: userService,
            followRepository: followRepository,
            userCache: userCache
        )
        let viewController = UserListViewController(
            viewModel: viewModel,
            imageLoader: imageLoader
        )

        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.setViewControllers([viewController], animated: false)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
