import Foundation
@testable import StackOverflowUsers

// MARK: - MockUserService

final class MockUserService: UserServiceProtocol, @unchecked Sendable {

    enum Outcome {
        case success([User], hasMore: Bool = false)
        case failure(AppError)
    }

    var outcome: Outcome = .success([])
    var pageOutcomes: [Int: Outcome] = [:]
    private(set) var fetchCallCount = 0
    private(set) var lastPageRequested: Int?
    private(set) var lastPageSizeRequested: Int?

    func fetchTopUsers(page: Int, pageSize: Int) async throws -> UserPage {
        fetchCallCount += 1
        lastPageRequested = page
        lastPageSizeRequested = pageSize
        let outcome = pageOutcomes[page] ?? self.outcome
        switch outcome {
        case .success(let users, let hasMore):
            return UserPage(users: users, hasMore: hasMore)
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - MockFollowRepository

final class MockFollowRepository: FollowRepositoryProtocol, @unchecked Sendable {

    private(set) var storage: Set<Int> = []

    init(initial: Set<Int> = []) {
        self.storage = initial
    }

    func followedUserIDs() async -> Set<Int> { storage }
    func isFollowing(userID: Int) async -> Bool { storage.contains(userID) }
    func follow(userID: Int) async { storage.insert(userID) }
    func unfollow(userID: Int) async { storage.remove(userID) }

    @discardableResult
    func toggle(userID: Int) async -> Bool {
        if storage.contains(userID) {
            storage.remove(userID)
            return false
        } else {
            storage.insert(userID)
            return true
        }
    }
}

// MARK: - MockUserCache

final class MockUserCache: UserCacheProtocol, @unchecked Sendable {

    var stored: [User]?
    private(set) var saveCallCount = 0
    private(set) var clearCallCount = 0

    init(stored: [User]? = nil) {
        self.stored = stored
    }

    func load() async -> [User]? { stored }

    func save(_ users: [User]) async {
        saveCallCount += 1
        stored = users
    }

    func clear() async {
        clearCallCount += 1
        stored = nil
    }
}

// MARK: - User builder

extension User {
    static func fixture(
        userId: Int = 1,
        displayName: String = "Test User",
        reputation: Int = 100,
        profileImage: URL? = URL(string: "https://example.com/avatar.png"),
        location: String? = nil,
        acceptRate: Int? = nil
    ) -> User {
        User(
            userId: userId,
            displayName: displayName,
            reputation: reputation,
            profileImage: profileImage,
            location: location,
            link: URL(string: "https://stackoverflow.com/users/\(userId)")!,
            badgeCounts: BadgeCounts(gold: 1, silver: 2, bronze: 3),
            acceptRate: acceptRate
        )
    }
}
