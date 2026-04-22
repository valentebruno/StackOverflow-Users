import Foundation

#if DEBUG

// MARK: - UITestingHooks

enum UITestingHooks {

    static let launchFlag = "-UITests"

    static var isRunning: Bool {
        CommandLine.arguments.contains(launchFlag)
    }

    // MARK: - Stub user service

    static func makeUserService() -> UserServiceProtocol {
        StubUserService()
    }

    static func makeFollowRepository() -> FollowRepositoryProtocol {
        let suite = UserDefaults(suiteName: "com.brunovalente.StackOverflowUsers.UITests")
            ?? .standard
        suite.removePersistentDomain(forName: "com.brunovalente.StackOverflowUsers.UITests")
        return UserDefaultsFollowRepository(defaults: suite)
    }

    static func makeUserCache() -> UserCacheProtocol? {
        nil
    }
}

// MARK: - StubUserService

private final class StubUserService: UserServiceProtocol, @unchecked Sendable {

    func fetchTopUsers(page: Int, pageSize: Int) async throws -> UserPage {
        let users = Self.fixture
        return UserPage(users: users, hasMore: false)
    }

    private static let fixture: [User] = [
        User(
            userId:       101,
            displayName:  "Jon Skeet",
            reputation:   1_454_978,
            profileImage: nil,
            location:     "Reading, UK",
            link:         URL(string: "https://stackoverflow.com/users/101"),
            badgeCounts:  BadgeCounts(gold: 888, silver: 8499, bronze: 9527),
            acceptRate:   85
        ),
        User(
            userId:       202,
            displayName:  "Gordon Linoff",
            reputation:   1_298_765,
            profileImage: nil,
            location:     "New York, USA",
            link:         URL(string: "https://stackoverflow.com/users/202"),
            badgeCounts:  BadgeCounts(gold: 260, silver: 1800, bronze: 2700),
            acceptRate:   nil
        ),
        User(
            userId:       303,
            displayName:  "VonC",
            reputation:   987_654,
            profileImage: nil,
            location:     "Paris, France",
            link:         URL(string: "https://stackoverflow.com/users/303"),
            badgeCounts:  BadgeCounts(gold: 110, silver: 900, bronze: 1400),
            acceptRate:   80
        )
    ]
}

#endif
