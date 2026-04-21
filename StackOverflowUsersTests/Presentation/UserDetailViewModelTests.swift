import XCTest
@testable import StackOverflowUsers

// MARK: - UserDetailViewModelTests

final class UserDetailViewModelTests: XCTestCase {

    // MARK: - Formatting

    func test_formattedReputation_includesDecimalGroupingAndSuffix() {
        let vm = UserDetailViewModel(user: makeUser(reputation: 1_454_978))
        XCTAssertTrue(vm.formattedReputation.hasSuffix(" reputation"))
        XCTAssertEqual(vm.formattedReputation.filter(\.isNumber), "1454978")
    }

    func test_location_trimsWhitespaceAndNilsOutEmpty() {
        let withLocation = UserDetailViewModel(user: makeUser(location: "  Lisbon  "))
        XCTAssertEqual(withLocation.location, "Lisbon")

        let blank = UserDetailViewModel(user: makeUser(location: "   "))
        XCTAssertNil(blank.location)

        let absent = UserDetailViewModel(user: makeUser(location: nil))
        XCTAssertNil(absent.location)
    }

    // MARK: - Badges

    func test_badgeCounts_defaultToZeroWhenAbsent() {
        let user = User(
            userId: 1, displayName: "A", reputation: 0,
            profileImage: nil, location: nil, link: nil,
            badgeCounts: nil, acceptRate: nil
        )
        let vm = UserDetailViewModel(user: user)

        XCTAssertEqual(vm.goldBadges, 0)
        XCTAssertEqual(vm.silverBadges, 0)
        XCTAssertEqual(vm.bronzeBadges, 0)
        XCTAssertFalse(vm.hasBadges)
    }

    func test_hasBadges_isTrueWhenAnyCountIsNonZero() {
        let user = User(
            userId: 1, displayName: "A", reputation: 0,
            profileImage: nil, location: nil, link: nil,
            badgeCounts: BadgeCounts(gold: 0, silver: 0, bronze: 3),
            acceptRate: nil
        )
        let vm = UserDetailViewModel(user: user)
        XCTAssertTrue(vm.hasBadges)
    }

    // MARK: - Accept rate

    func test_formattedAcceptRate_returnsNilWhenAbsent() {
        let vm = UserDetailViewModel(user: makeUser(acceptRate: nil))
        XCTAssertNil(vm.formattedAcceptRate)
    }

    func test_formattedAcceptRate_appendsPercentSuffix() {
        let vm = UserDetailViewModel(user: makeUser(acceptRate: 85))
        XCTAssertEqual(vm.formattedAcceptRate, "85% accept rate")
    }

    // MARK: - Profile URL

    func test_profileURL_forwardsUserLink() {
        let link = URL(string: "https://stackoverflow.com/users/42/jon-skeet")!
        let vm = UserDetailViewModel(user: makeUser(link: link))
        XCTAssertEqual(vm.profileURL, link)
    }

    // MARK: - Helpers

    private func makeUser(
        reputation: Int = 100,
        location: String? = nil,
        link: URL = URL(string: "https://stackoverflow.com/users/1")!,
        acceptRate: Int? = 50
    ) -> User {
        User(
            userId: 1,
            displayName: "Test User",
            reputation: reputation,
            profileImage: nil,
            location: location,
            link: link,
            badgeCounts: BadgeCounts(gold: 1, silver: 2, bronze: 3),
            acceptRate: acceptRate
        )
    }
}
