import XCTest
@testable import StackOverflowUsers

// MARK: - FollowRepositoryTests

final class FollowRepositoryTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var repository: UserDefaultsFollowRepository!

    override func setUp() {
        super.setUp()
        suiteName = "follow-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        repository = UserDefaultsFollowRepository(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Follow / Unfollow

    func test_follow_addsID() async {
        await repository.follow(userID: 42)
        let result = await repository.isFollowing(userID: 42)
        XCTAssertTrue(result)
    }

    func test_unfollow_removesID() async {
        await repository.follow(userID: 42)
        await repository.unfollow(userID: 42)
        let result = await repository.isFollowing(userID: 42)
        XCTAssertFalse(result)
    }

    func test_followedUserIDs_returnsAll() async {
        await repository.follow(userID: 1)
        await repository.follow(userID: 2)
        await repository.follow(userID: 3)

        let ids = await repository.followedUserIDs()
        XCTAssertEqual(ids, [1, 2, 3])
    }

    // MARK: - Toggle

    func test_toggle_onFreshID_follows() async {
        let isNowFollowing = await repository.toggle(userID: 7)
        XCTAssertTrue(isNowFollowing)
        let stored = await repository.isFollowing(userID: 7)
        XCTAssertTrue(stored)
    }

    func test_toggle_onFollowedID_unfollows() async {
        await repository.follow(userID: 7)
        let isNowFollowing = await repository.toggle(userID: 7)
        XCTAssertFalse(isNowFollowing)
        let stored = await repository.isFollowing(userID: 7)
        XCTAssertFalse(stored)
    }

    // MARK: - Persistence

    func test_persistence_survivesRepositoryReinstantiation() async {
        await repository.follow(userID: 99)

        let reborn = UserDefaultsFollowRepository(defaults: defaults)
        let stored = await reborn.isFollowing(userID: 99)

        XCTAssertTrue(stored)
    }

    // MARK: - Concurrency

    func test_concurrentToggles_produceDeterministicState() async {
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask { await self.repository.follow(userID: 500) }
            }
        }

        let ids = await repository.followedUserIDs()
        XCTAssertEqual(ids, [500])
    }
}
