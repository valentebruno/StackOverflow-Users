import Foundation

// MARK: - UserListViewModel

@MainActor
final class UserListViewModel {

    // MARK: - Filter

    enum Filter: Equatable, Sendable {
        case all
        case followed
    }

    // MARK: - ViewState

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded([UserCellModel])
        case empty(EmptyReason)
        case failed(AppError, stale: [UserCellModel])
    }

    enum EmptyReason: Equatable, Sendable {
        case nothingFollowed
    }

    // MARK: - Output

    private(set) var state: ViewState = .idle {
        didSet { onStateChange?(state) }
    }

    private(set) var filter: Filter = .all

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
                self.emitDataState(followedIDs: followed)
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
            self.emitDataState(followedIDs: followed)
        }
    }

    func setFilter(_ newFilter: Filter) {
        guard newFilter != filter else { return }
        filter = newFilter
        Task { [weak self] in
            guard let self else { return }
            let followed = await self.followRepository.followedUserIDs()
            self.emitDataState(followedIDs: followed)
        }
    }

    // MARK: - Private

    private func emitDataState(followedIDs: Set<Int>) {
        let all = Self.cellModels(from: users, followedIDs: followedIDs)
        switch filter {
        case .all:
            state = .loaded(all)
        case .followed:
            let followedOnly = all.filter { $0.isFollowed }
            state = followedOnly.isEmpty ? .empty(.nothingFollowed) : .loaded(followedOnly)
        }
    }

    private func currentCellModels() -> [UserCellModel] {
        switch state {
        case .loaded(let models):   return models
        case .failed(_, let stale): return stale
        case .idle, .loading, .empty: return []
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
