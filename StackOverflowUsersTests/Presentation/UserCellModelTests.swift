import XCTest
@testable import StackOverflowUsers

// MARK: - UserCellModelTests

final class UserCellModelTests: XCTestCase {

    // MARK: - Reputation formatting

    func test_formattedReputation_usesLocaleAwareThousandsSeparators() {
        let model = makeModel(reputation: 1_454_978)
        let digitsOnly = model.formattedReputation.filter { $0.isNumber }
        XCTAssertEqual(digitsOnly, "1454978")

        // The grouping separator varies by locale (comma, space, NBSP, apostrophe…),
        // so assert indirectly: the string is longer than the raw digits plus " rep".
        let minimum = "\(digitsOnly) rep".count
        XCTAssertGreaterThan(model.formattedReputation.count, minimum)
    }

    func test_formattedReputation_smallNumbers_haveNoSeparator() {
        let model = makeModel(reputation: 42)
        XCTAssertEqual(model.formattedReputation, "42 rep")
    }

    func test_formattedReputation_alwaysEndsWithRep() {
        let model = makeModel(reputation: 9_999)
        XCTAssertTrue(model.formattedReputation.hasSuffix(" rep"))
    }

    // MARK: - Identity

    func test_equality_usesAllVisibleProperties() {
        let a = makeModel(userID: 1, isFollowed: false)
        let b = makeModel(userID: 1, isFollowed: false)
        let c = makeModel(userID: 1, isFollowed: true)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - Helpers

    private func makeModel(
        userID: Int = 1,
        reputation: Int = 100,
        isFollowed: Bool = false
    ) -> UserCellModel {
        UserCellModel(
            userID: userID,
            displayName: "Jon",
            profileImageURL: nil,
            reputation: reputation,
            isFollowed: isFollowed
        )
    }
}
