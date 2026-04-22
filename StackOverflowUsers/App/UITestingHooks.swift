import Foundation

#if DEBUG

// MARK: - UITestingHooks

enum UITestingHooks {

    static let launchFlag = "-UITests"
    private static let failureFlag = "-UITests-FailNetwork"

    static var isRunning: Bool {
        CommandLine.arguments.contains(launchFlag)
    }

    // MARK: - Stub user service

    static func makeUserService() -> UserServiceProtocol {
        StubUserService(
            shouldFail: CommandLine.arguments.contains(failureFlag)
        )
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

    private let shouldFail: Bool

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func fetchTopUsers(page: Int, pageSize: Int) async throws -> UserPage {
        if shouldFail {
            throw AppError.networkUnavailable
        }
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
        ),
        User(
            userId:       404,
            displayName:  "Martijn Pieters",
            reputation:   1_141_315,
            profileImage: nil,
            location:     "London, UK",
            link:         URL(string: "https://stackoverflow.com/users/404"),
            badgeCounts:  BadgeCounts(gold: 345, silver: 2100, bronze: 3500),
            acceptRate:   90
        ),
        User(
            userId:       505,
            displayName:  "BalusC",
            reputation:   1_115_549,
            profileImage: nil,
            location:     "Amsterdam, Netherlands",
            link:         URL(string: "https://stackoverflow.com/users/505"),
            badgeCounts:  BadgeCounts(gold: 410, silver: 1600, bronze: 2200),
            acceptRate:   88
        ),
        User(
            userId:       606,
            displayName:  "T.J. Crowder",
            reputation:   1_083_181,
            profileImage: nil,
            location:     "Coventry, UK",
            link:         URL(string: "https://stackoverflow.com/users/606"),
            badgeCounts:  BadgeCounts(gold: 190, silver: 1400, bronze: 1900),
            acceptRate:   nil
        ),
        User(
            userId:       707,
            displayName:  "Marc Gravell",
            reputation:   1_072_147,
            profileImage: nil,
            location:     "Wiltshire, UK",
            link:         URL(string: "https://stackoverflow.com/users/707"),
            badgeCounts:  BadgeCounts(gold: 520, silver: 2800, bronze: 3100),
            acceptRate:   82
        ),
        User(
            userId:       808,
            displayName:  "Darin Dimitrov",
            reputation:   1_042_719,
            profileImage: nil,
            location:     "Sofia, Bulgaria",
            link:         URL(string: "https://stackoverflow.com/users/808"),
            badgeCounts:  BadgeCounts(gold: 300, silver: 1700, bronze: 2500),
            acceptRate:   75
        ),
        User(
            userId:       909,
            displayName:  "CommonsWare",
            reputation:   1_011_727,
            profileImage: nil,
            location:     nil,
            link:         URL(string: "https://stackoverflow.com/users/909"),
            badgeCounts:  BadgeCounts(gold: 220, silver: 1100, bronze: 1600),
            acceptRate:   nil
        ),
        User(
            userId:       1010,
            displayName:  "Greg Hewgill",
            reputation:   1_005_969,
            profileImage: nil,
            location:     "Christchurch, New Zealand",
            link:         URL(string: "https://stackoverflow.com/users/1010"),
            badgeCounts:  BadgeCounts(gold: 175, silver: 950, bronze: 1350),
            acceptRate:   91
        )
    ]
}

#endif
