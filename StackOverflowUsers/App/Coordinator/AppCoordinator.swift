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
        configureAppearance()

        let splashViewController = SplashViewController()
        splashViewController.onFinish = { [weak self] in
            self?.showUserList(animated: true)
        }

        window.rootViewController = splashViewController
        window.makeKeyAndVisible()
    }

    private func showUserList(animated: Bool) {
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

        navigationController.navigationBar.prefersLargeTitles = false
        navigationController.setViewControllers([viewController], animated: false)

        guard animated else {
            window.rootViewController = navigationController
            return
        }

        UIView.transition(
            with: window,
            duration: 0.2,
            options: [.transitionCrossDissolve, .allowAnimatedContent]
        ) {
            self.window.rootViewController = self.navigationController
        }
    }

    private func configureAppearance() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = StackOverflowPalette.contentBackground
        navigationAppearance.titleTextAttributes = StackOverflowTypography.textAttributes(
            .body3,
            weight: .semibold,
            color: StackOverflowPalette.textPrimary
        )
        navigationAppearance.largeTitleTextAttributes = StackOverflowTypography.textAttributes(
            .headline2,
            weight: .semibold,
            color: StackOverflowPalette.textPrimary
        )

        navigationController.navigationBar.tintColor = StackOverflowPalette.primaryAction
        navigationController.navigationBar.standardAppearance = navigationAppearance
        navigationController.navigationBar.compactAppearance = navigationAppearance
        navigationController.navigationBar.scrollEdgeAppearance = navigationAppearance
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
