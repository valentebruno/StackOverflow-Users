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
        let userService: UserServiceProtocol
        let followRepository: FollowRepositoryProtocol
        let userCache: UserCacheProtocol?

        if UITestingHooks.isRunning {
            userService      = UITestingHooks.makeUserService()
            followRepository = UITestingHooks.makeFollowRepository()
            userCache        = UITestingHooks.makeUserCache()
        } else {
            userService      = UserService()
            followRepository = UserDefaultsFollowRepository()
            userCache        = FileUserCache()
        }

        let imageLoader = ImageLoader.shared

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
