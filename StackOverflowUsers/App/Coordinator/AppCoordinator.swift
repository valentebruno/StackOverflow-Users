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

        #if DEBUG
        if UITestingHooks.isRunning {
            userService      = UITestingHooks.makeUserService()
            followRepository = UITestingHooks.makeFollowRepository()
            userCache        = UITestingHooks.makeUserCache()
        } else {
            userService      = UserService()
            followRepository = UserDefaultsFollowRepository()
            userCache        = FileUserCache()
        }
        #else
        userService      = UserService()
        followRepository = UserDefaultsFollowRepository()
        userCache        = FileUserCache()
        #endif

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
        viewController.onSelectUser = { [weak self] user in
            self?.showDetail(for: user, imageLoader: imageLoader)
        }

        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.setViewControllers([viewController], animated: false)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    // MARK: - Navigation

    private func showDetail(for user: User, imageLoader: ImageLoading) {
        let detailVM = UserDetailViewModel(user: user)
        let detailVC = UserDetailViewController(
            viewModel: detailVM,
            imageLoader: imageLoader,
            urlOpener: { url in UIApplication.shared.open(url) }
        )
        navigationController.pushViewController(detailVC, animated: true)
    }
}
