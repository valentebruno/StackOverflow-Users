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

    // MARK: - Pagination

    private let pageSize: Int
    private var users: [User] = []
    private var currentPage: Int = 0
    private var hasMorePages: Bool = false
    private var isFetchingNextPage: Bool = false
    private var loadTask: Task<Void, Never>?
    private var nextPageTask: Task<Void, Never>?

    init(
        userService: UserServiceProtocol,
        followRepository: FollowRepositoryProtocol,
        pageSize: Int = 20
    ) {
        self.userService = userService
        self.followRepository = followRepository
        self.pageSize = pageSize
    }

    deinit {
        loadTask?.cancel()
        nextPageTask?.cancel()
    }

    // MARK: - Intents

    func load() {
        loadTask?.cancel()
        nextPageTask?.cancel()
        isFetchingNextPage = false

        let staleCellModels = currentCellModels()
        state = .loading

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await self.userService.fetchTopUsers(page: 1, pageSize: self.pageSize)
                guard !Task.isCancelled else { return }
                let followed = await self.followRepository.followedUserIDs()
                self.users = page.users
                self.currentPage = 1
                self.hasMorePages = page.hasMore
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

    func loadNextPage() {
        guard hasMorePages, !isFetchingNextPage else { return }
        guard filter == .all else { return }
        guard case .loaded = state else { return }

        isFetchingNextPage = true
        let nextPage = currentPage + 1

        nextPageTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isFetchingNextPage = false }
            do {
                let page = try await self.userService.fetchTopUsers(page: nextPage, pageSize: self.pageSize)
                guard !Task.isCancelled else { return }
                let followed = await self.followRepository.followedUserIDs()
                self.users.append(contentsOf: page.users)
                self.currentPage = nextPage
                self.hasMorePages = page.hasMore
                self.emitDataState(followedIDs: followed)
            } catch {
                return
            }
        }
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
        case .loaded(let models):     return models
        case .failed(_, let stale):   return stale
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
