import Foundation

// MARK: - UserListViewModel

@MainActor
final class UserListViewModel {

    // MARK: - ViewState

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded([UserCellModel])
        case failed(AppError, stale: [UserCellModel])
    }

    // MARK: - Output

    private(set) var state: ViewState = .idle {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((ViewState) -> Void)?

    // MARK: - Dependencies

    private let userService: UserServiceProtocol
    private let followRepository: FollowRepositoryProtocol

    private var users: [User] = []
    private var loadTask: Task<Void, Never>?

    init(
        userService: UserServiceProtocol,
        followRepository: FollowRepositoryProtocol
    ) {
        self.userService = userService
        self.followRepository = followRepository
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Intents

    func load() {
        loadTask?.cancel()

        let staleCellModels = currentCellModels()
        state = .loading

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let fetched = try await self.userService.fetchTopUsers()
                guard !Task.isCancelled else { return }
                let followed = await self.followRepository.followedUserIDs()
                self.users = fetched
                self.state = .loaded(Self.cellModels(from: fetched, followedIDs: followed))
            } catch let error as AppError {
                guard !Task.isCancelled else { return }
                self.state = .failed(error, stale: staleCellModels)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self.state = .failed(.networkUnavailable, stale: staleCellModels)
            }
        }
    }

    func retry() {
        load()
    }

    func toggleFollow(userID: Int) {
        Task { [weak self] in
            guard let self else { return }
            _ = await self.followRepository.toggle(userID: userID)
            let followed = await self.followRepository.followedUserIDs()
            self.state = .loaded(Self.cellModels(from: self.users, followedIDs: followed))
        }
    }

    // MARK: - Private

    private func currentCellModels() -> [UserCellModel] {
        switch state {
        case .loaded(let models):           return models
        case .failed(_, let stale):         return stale
        case .idle, .loading:               return []
        }
    }

    private static func cellModels(
        from users: [User],
        followedIDs: Set<Int>
    ) -> [UserCellModel] {
        users.map { user in
            UserCellModel(
                userID:          user.userId,
                displayName:     user.displayName,
                profileImageURL: user.profileImage,
                reputation:      user.reputation,
                isFollowed:      followedIDs.contains(user.userId)
            )
        }
    }
}
