import XCTest
@testable import StackOverflowUsers

// MARK: - UserListViewModelTests

@MainActor
final class UserListViewModelTests: XCTestCase {

    private var userService: MockUserService!
    private var followRepository: MockFollowRepository!
    private var viewModel: UserListViewModel!

    override func setUp() {
        super.setUp()
        userService = MockUserService()
        followRepository = MockFollowRepository()
        viewModel = UserListViewModel(
            userService: userService,
            followRepository: followRepository
        )
    }

    override func tearDown() {
        viewModel = nil
        userService = nil
        followRepository = nil
        super.tearDown()
    }

    // MARK: - Load

    func test_load_onSuccess_emitsLoadingThenLoaded() async {
        userService.outcome = .success([.fixture(userId: 1, displayName: "Ann")])
        let recorder = makeRecorder(expecting: 2)

        viewModel.load()
        let recorded = await recorder.wait()

        XCTAssertEqual(recorded.count, 2)
        XCTAssertEqual(recorded.first, .loading)
        if case .loaded(let models) = recorded.last {
            XCTAssertEqual(models.map(\.userID), [1])
        } else {
            XCTFail("Expected loaded state, got \(String(describing: recorded.last))")
        }
    }

    func test_load_onNetworkError_emitsFailedWithMatchingError() async {
        userService.outcome = .failure(.networkUnavailable)
        let recorder = makeRecorder(expecting: 2)

        viewModel.load()
        let recorded = await recorder.wait()

        if case .failed(let error, let stale) = recorded.last {
            XCTAssertEqual(error, .networkUnavailable)
            XCTAssertTrue(stale.isEmpty)
        } else {
            XCTFail("Expected failed state")
        }
    }

    func test_load_onServerError_emitsFailedWithStatusCode() async {
        userService.outcome = .failure(.serverError(503))
        let recorder = makeRecorder(expecting: 2)

        viewModel.load()
        let recorded = await recorder.wait()

        if case .failed(let error, _) = recorded.last {
            XCTAssertEqual(error, .serverError(503))
        } else {
            XCTFail("Expected failed state")
        }
    }

    func test_load_onAPIErrorWrapper_emitsFailed() async {
        userService.outcome = .failure(.apiError(id: 502, name: "throttle_violation", message: "slow down"))
        let recorder = makeRecorder(expecting: 2)

        viewModel.load()
        let recorded = await recorder.wait()

        if case .failed(let error, _) = recorded.last {
            XCTAssertEqual(error, .apiError(id: 502, name: "throttle_violation", message: "slow down"))
        } else {
            XCTFail("Expected failed state")
        }
    }

    // MARK: - Stale preservation

    func test_load_afterSuccess_failureKeepsStaleModels() async {
        userService.outcome = .success([.fixture(userId: 1)])
        let firstRecorder = makeRecorder(expecting: 2)
        viewModel.load()
        _ = await firstRecorder.wait()

        userService.outcome = .failure(.networkUnavailable)
        let secondRecorder = makeRecorder(expecting: 2)
        viewModel.load()
        let recorded = await secondRecorder.wait()

        if case .failed(_, let stale) = recorded.last {
            XCTAssertEqual(stale.map(\.userID), [1])
        } else {
            XCTFail("Expected failed state with stale models")
        }
    }

    // MARK: - Follow toggle

    func test_toggleFollow_updatesCellModel() async {
        userService.outcome = .success([.fixture(userId: 1)])
        let loadRecorder = makeRecorder(expecting: 2)
        viewModel.load()
        _ = await loadRecorder.wait()

        let toggleRecorder = makeRecorder(expecting: 1)
        viewModel.toggleFollow(userID: 1)
        let recorded = await toggleRecorder.wait()

        if case .loaded(let models) = recorded.last {
            XCTAssertTrue(models.first?.isFollowed == true)
        } else {
            XCTFail("Expected loaded with followed flag flipped")
        }
    }

    // MARK: - Filter

    func test_setFilter_toFollowedWithNoFollows_emitsEmptyState() async {
        userService.outcome = .success([
            .fixture(userId: 1, displayName: "Ann"),
            .fixture(userId: 2, displayName: "Bob")
        ])
        let initial = makeRecorder(expecting: 2)
        viewModel.load()
        _ = await initial.wait()

        let after = makeRecorder(expecting: 1)
        viewModel.setFilter(.followed)
        let recorded = await after.wait()

        XCTAssertEqual(recorded.last, .empty(.nothingFollowed))
    }

    func test_setFilter_toFollowedWithFollows_emitsFilteredList() async {
        followRepository = MockFollowRepository(initial: [2])
        viewModel = UserListViewModel(userService: userService, followRepository: followRepository)
        userService.outcome = .success([
            .fixture(userId: 1, displayName: "Ann"),
            .fixture(userId: 2, displayName: "Bob"),
            .fixture(userId: 3, displayName: "Cam")
        ])
        let initial = makeRecorder(expecting: 2)
        viewModel.load()
        _ = await initial.wait()

        let after = makeRecorder(expecting: 1)
        viewModel.setFilter(.followed)
        let recorded = await after.wait()

        if case .loaded(let models) = recorded.last {
            XCTAssertEqual(models.map(\.userID), [2])
            XCTAssertTrue(models.first?.isFollowed == true)
        } else {
            XCTFail("Expected loaded with only followed users, got \(String(describing: recorded.last))")
        }
    }

    func test_setFilter_backToAll_restoresFullList() async {
        followRepository = MockFollowRepository(initial: [1])
        viewModel = UserListViewModel(userService: userService, followRepository: followRepository)
        userService.outcome = .success([
            .fixture(userId: 1, displayName: "Ann"),
            .fixture(userId: 2, displayName: "Bob")
        ])
        let initial = makeRecorder(expecting: 2)
        viewModel.load()
        _ = await initial.wait()

        let first = makeRecorder(expecting: 1)
        viewModel.setFilter(.followed)
        _ = await first.wait()

        let second = makeRecorder(expecting: 1)
        viewModel.setFilter(.all)
        let recorded = await second.wait()

        if case .loaded(let models) = recorded.last {
            XCTAssertEqual(models.map(\.userID), [1, 2])
        } else {
            XCTFail("Expected loaded with all users")
        }
    }

    // MARK: - Initial followed state

    func test_load_withPreexistingFollowedIDs_reflectsInModels() async {
        followRepository = MockFollowRepository(initial: [1])
        viewModel = UserListViewModel(userService: userService, followRepository: followRepository)
        userService.outcome = .success([
            .fixture(userId: 1, displayName: "Ann"),
            .fixture(userId: 2, displayName: "Bob")
        ])
        let recorder = makeRecorder(expecting: 2)

        viewModel.load()
        let recorded = await recorder.wait()

        if case .loaded(let models) = recorded.last {
            XCTAssertEqual(models.first { $0.userID == 1 }?.isFollowed, true)
            XCTAssertEqual(models.first { $0.userID == 2 }?.isFollowed, false)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    // MARK: - Helpers

    private func makeRecorder(expecting count: Int, timeout: TimeInterval = 2) -> StateRecorder {
        let recorder = StateRecorder(target: count, timeout: timeout)
        viewModel.onStateChange = { [weak recorder] state in
            recorder?.handle(state)
        }
        return recorder
    }
}

// MARK: - StateRecorder

@MainActor
private final class StateRecorder {

    private let target: Int
    private let timeout: TimeInterval
    private var states: [UserListViewModel.ViewState] = []
    private var continuation: CheckedContinuation<[UserListViewModel.ViewState], Never>?
    private var timeoutTask: Task<Void, Never>?

    init(target: Int, timeout: TimeInterval) {
        self.target = target
        self.timeout = timeout
    }

    func handle(_ state: UserListViewModel.ViewState) {
        states.append(state)
        if states.count >= target { resume() }
    }

    func wait() async -> [UserListViewModel.ViewState] {
        if states.count >= target { return states }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            timeoutTask = Task { [weak self, timeout] in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                await self?.resume()
            }
        }
    }

    private func resume() {
        guard let continuation else { return }
        self.continuation = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        continuation.resume(returning: states)
    }
}
